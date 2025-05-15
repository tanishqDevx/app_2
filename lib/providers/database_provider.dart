import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/models/transaction.dart' as model;
import 'package:credit_tracker/models/credit.dart';
import 'package:credit_tracker/models/daily_summary.dart';
import 'package:credit_tracker/models/payment_method.dart';

class DatabaseProvider with ChangeNotifier {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'credit_tracker.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        sales REAL DEFAULT 0,
        cash REAL DEFAULT 0,
        payment REAL DEFAULT 0,
        transaction_type TEXT CHECK(transaction_type IN ('sale', 'repayment', 'expense')),
        total_received REAL DEFAULT 0,
        outstanding REAL DEFAULT 0,
        related_credit_id INTEGER
      )
    ''');
    
    // Payment methods table
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');
    
    // Create indexes for faster lookups
    await db.execute('CREATE INDEX idx_customer_name ON transactions(customer_name)');
    await db.execute('CREATE INDEX idx_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transaction_id ON payment_methods(transaction_id)');
  }
  
  // Replace the _upgradeDb function with this dynamic version
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // First, get table info to identify existing columns
      final List<Map<String, dynamic>> tableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      List<String> paymentMethodColumns = [];
      
      // Find payment method columns (excluding standard columns)
      for (var column in tableInfo) {
        final columnName = column['name'] as String;
        // Skip standard columns
        if (!['id', 'date', 'customer_name', 'sales', 'cash', 'payment', 
             'transaction_type', 'outstanding', 'related_credit_id'].contains(columnName)) {
          paymentMethodColumns.add(columnName);
        }
      }
      
      // Add total_received column if upgrading from version 1
      await db.execute('ALTER TABLE transactions ADD COLUMN total_received REAL DEFAULT 0');
      
      // Create payment_methods table if upgrading from version 1
      await db.execute('''
        CREATE TABLE payment_methods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          method TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX idx_transaction_id ON payment_methods(transaction_id)');
      
      // Migrate existing data
      final List<Map<String, dynamic>> transactions = await db.query('transactions');
      
      for (var transaction in transactions) {
        final id = transaction['id'] as int;
        final cash = transaction['cash'] as double? ?? 0;
        
        // Calculate total received and migrate payment methods
        double totalReceived = cash;
        
        // Process each payment method column dynamically
        for (String methodColumn in paymentMethodColumns) {
          final amount = transaction[methodColumn] as double? ?? 0;
          if (amount > 0) {
            // Insert the payment method with the actual column name
            await db.insert('payment_methods', {
              'transaction_id': id,
              'method': methodColumn.toUpperCase(), // Use the column name as the method name
              'amount': amount,
            });
            
            totalReceived += amount;
          }
        }
        
        // Update transaction with total_received
        await db.update(
          'transactions',
          {'total_received': totalReceived},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<void> init() async {
    await database;
  }

  // Process Excel file with dynamic column detection
  Future<Map<String, dynamic>> processExcelFile(File file, String date) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    final db = await database;
    int rowsProcessed = 0;
    
    // Start a transaction for better performance
    await db.transaction((txn) async {
      // Get the first sheet
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      
      if (rows.length < 3) {
        throw Exception('Excel file does not have enough rows');
      }
      
      // Get the header row (second row in the sheet)
      final headerRow = rows[1];
      
      // Find column indexes dynamically
      Map<String, int> columnIndexes = {};
      Map<int, String> paymentMethodColumns = {};
      int particularsIndex = -1;
      int salesIndex = -1;
      int cashIndex = -1;
      int paymentIndex = -1;
      
      for (int i = 0; i < headerRow.length; i++) {
        final cell = headerRow[i];
        if (cell == null) continue;
        
        final value = cell.value.toString().toLowerCase();
        
        if (value.contains('particular')) {
          particularsIndex = i;
          columnIndexes['particulars'] = i;
        } else if (value.contains('sale')) {
          salesIndex = i;
          columnIndexes['sales'] = i;
        } else if (value.contains('cash')) {
          cashIndex = i;
          columnIndexes['cash'] = i;
        } else if (value.contains('payment')) {
          paymentIndex = i;
          columnIndexes['payment'] = i;
        }
      }
      
      // Ensure we have the required columns
      if (particularsIndex == -1) {
        throw Exception('Could not find "Particulars" column');
      }
      if (salesIndex == -1) {
        throw Exception('Could not find "SALES" column');
      }
      if (cashIndex == -1) {
        throw Exception('Could not find "CASH" column');
      }
      if (paymentIndex == -1) {
        throw Exception('Could not find "PAYMENT" column');
      }
      
      // Identify payment method columns (between CASH and PAYMENT)
      for (int i = cashIndex + 1; i < paymentIndex; i++) {
        final cell = headerRow[i];
        if (cell != null && cell.value != null) {
          final methodName = cell.value.toString().trim();
          if (methodName.isNotEmpty) {
            paymentMethodColumns[i] = methodName;
          }
        }
      }
      
      // Process each row (start from the third row)
      for (int i = 2; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= particularsIndex) continue;
        
        // Extract customer name
        final nameCell = row[particularsIndex];
        if (nameCell == null || nameCell.value.toString().trim().isEmpty) continue;
        
        final customerName = nameCell.value.toString().trim();
        
        // Skip rows with specific keywords or TOTAL row
        if (customerName.toLowerCase().contains('manoj ji') || 
            customerName.toLowerCase().contains('cash in office') ||
            customerName.toLowerCase().contains('total')) {
          continue;
        }
        
        // Extract sales amount
        final sales = _getCellNumericValue(row, salesIndex);
        
        // Extract cash amount
        final cash = _getCellNumericValue(row, cashIndex);
        
        // Extract payment (expense) amount
        final payment = _getCellNumericValue(row, paymentIndex);
        
        // Extract all payment method amounts
        Map<String, double> paymentMethods = {};
        double totalDigitalPayments = 0;
        
        for (var entry in paymentMethodColumns.entries) {
          final methodIndex = entry.key;
          final methodName = entry.value;
          
          if (methodIndex < row.length) {
            final amount = _getCellNumericValue(row, methodIndex);
            if (amount > 0) {
              paymentMethods[methodName] = amount;
              totalDigitalPayments += amount;
            }
          }
        }
        
        // Skip rows where all numeric values are 0
        if (sales == 0 && cash == 0 && totalDigitalPayments == 0 && payment == 0) continue;
        
        // Calculate total received
        final totalReceived = cash + totalDigitalPayments;
        
        // Determine transaction type and calculate outstanding
        double outstanding = 0;
        String transactionType;
        
        if (sales > 0) {
          // This is a sale
          transactionType = 'sale';
          outstanding = sales - totalReceived;
        } else if (totalReceived > 0 || cash > 0) {
          // This is a repayment
          transactionType = 'repayment';
        } else if (payment > 0) {
          // This is an expense
          transactionType = 'expense';
        } else {
          // Skip rows that don't fit any category
          continue;
        }
        
        // Insert transaction into database
        final transactionId = await txn.insert(
          'transactions',
          {
            'date': date,
            'customer_name': customerName,
            'sales': sales,
            'cash': cash,
            'payment': payment,
            'transaction_type': transactionType,
            'total_received': totalReceived,
            'outstanding': outstanding,
          },
        );
        
        // Insert payment methods
        for (var entry in paymentMethods.entries) {
          final methodName = entry.key;
          final amount = entry.value;
          
          await txn.insert(
            'payment_methods',
            {
              'transaction_id': transactionId,
              'method': methodName,
              'amount': amount,
            },
          );
        }
        
        rowsProcessed++;
      }
    });
    
    notifyListeners();
    
    return {
      'status': 'success',
      'rows_processed': rowsProcessed,
      'date': date,
    };
  }

  // Helper method to get numeric value from cell
  double _getCellNumericValue(List<dynamic> row, int index) {
    if (index >= row.length || row[index] == null) return 0;
    
    final cell = row[index];
    if (cell.value == null) return 0;
    
    if (cell.value is num) {
      return (cell.value as num).toDouble();
    } else {
      try {
        return double.parse(cell.value.toString().replaceAll(',', ''));
      } catch (e) {
        return 0;
      }
    }
  }

  // Get all transactions with payment methods
  Future<List<model.Transaction>> getTransactions({
    String? fromDate,
    String? toDate,
    String? customerName,
    String? transactionType,
  }) async {
    final db = await database;
    
    String query = 'SELECT * FROM transactions';
    List<String> conditions = [];
    List<dynamic> params = [];
    
    if (fromDate != null) {
      conditions.add('date >= ?');
      params.add(fromDate);
    }
    
    if (toDate != null) {
      conditions.add('date <= ?');
      params.add(toDate);
    }
    
    if (customerName != null) {
      conditions.add('customer_name = ?');
      params.add(customerName);
    }
    
    if (transactionType != null) {
      conditions.add('transaction_type = ?');
      params.add(transactionType);
    }
    
    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY date DESC, id DESC';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, params);
    
    // Create transactions
    List<model.Transaction> transactions = [];
    
    for (var map in maps) {
      final transaction = model.Transaction.fromMap(map);
      
      // Get payment methods for this transaction
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payment_methods',
        where: 'transaction_id = ?',
        whereArgs: [transaction.id],
      );
      
      // Add payment methods to transaction
      List<PaymentMethod> paymentMethods = paymentMaps.map((map) => 
        PaymentMethod.fromMap(map)
      ).toList();
      
      transaction.paymentMethods = paymentMethods;
      transactions.add(transaction);
    }
    
    return transactions;
  }

  // Get transactions by date
  Future<List<model.Transaction>> getTransactionsByDate(String date) async {
    return getTransactions(fromDate: date, toDate: date);
  }

  // Get transactions by customer
  Future<List<model.Transaction>> getTransactionsByCustomer(String customerName) async {
    return getTransactions(customerName: customerName);
  }

  // Get all credits (customers with outstanding balances)
  Future<List<Credit>> getCredits() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        customer_name,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) -
        SUM(CASE WHEN transaction_type = 'repayment' THEN total_received ELSE 0 END) as total_outstanding,
        MIN(date) as first_date,
        MAX(date) as last_date,
        JULIANDAY('now') - JULIANDAY(MIN(date)) as days_outstanding
      FROM transactions
      GROUP BY customer_name
      HAVING total_outstanding > 0
      ORDER BY days_outstanding DESC
    ''');
    
    return List.generate(maps.length, (i) {
      return Credit.fromMap(maps[i]);
    });
  }

  // Get credit details for a specific customer
  Future<Credit?> getCreditDetails(String customerName) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        customer_name,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) -
        SUM(CASE WHEN transaction_type = 'repayment' THEN total_received ELSE 0 END) as total_outstanding,
        MIN(date) as first_date,
        MAX(date) as last_date,
        JULIANDAY('now') - JULIANDAY(MIN(date)) as days_outstanding
      FROM transactions
      WHERE customer_name = ?
      GROUP BY customer_name
    ''', [customerName]);
    
    if (maps.isEmpty) return null;
    
    return Credit.fromMap(maps.first);
  }

  // Get payment timeline for a customer
  Future<Map<String, dynamic>> getCreditTimeline(String customerName) async {
    final db = await database;
    
    // Get timeline data
    final List<Map<String, dynamic>> timelineMaps = await db.rawQuery('''
      SELECT 
        date,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) -
        SUM(CASE WHEN transaction_type = 'repayment' THEN total_received ELSE 0 END) as balance
      FROM transactions
      WHERE customer_name = ?
      GROUP BY date
      ORDER BY date
    ''', [customerName]);
    
    // Get payment method breakdown
    final List<Map<String, dynamic>> paymentMaps = await db.rawQuery('''
      SELECT 
        pm.method,
        SUM(pm.amount) as total_amount
      FROM payment_methods pm
      JOIN transactions t ON pm.transaction_id = t.id
      WHERE t.customer_name = ? AND t.transaction_type IN ('sale', 'repayment')
      GROUP BY pm.method
    ''', [customerName]);
    
    // Get cash total
    final List<Map<String, dynamic>> cashMaps = await db.rawQuery('''
      SELECT 
        SUM(cash) as cash_total
      FROM transactions
      WHERE customer_name = ? AND cash > 0
    ''', [customerName]);
    
    final cashTotal = cashMaps.first['cash_total'] ?? 0;
    
    List<Map<String, dynamic>> paymentMethods = [];
    double totalPayments = cashTotal;
    
    // Add digital payment methods
    for (var map in paymentMaps) {
      totalPayments += map['total_amount'] as double;
    }
    
    if (totalPayments > 0) {
      // Add cash if present
      if (cashTotal > 0) {
        int percentage = (cashTotal / totalPayments * 100).round();
        paymentMethods.add({
          'method': 'Cash',
          'percentage': percentage,
        });
      }
      
      // Add digital payment methods
      for (var map in paymentMaps) {
        int percentage = ((map['total_amount'] as double) / totalPayments * 100).round();
        paymentMethods.add({
          'method': map['method'],
          'percentage': percentage,
        });
      }
    }
    
    return {
      'timeline': timelineMaps,
      'payment_methods': paymentMethods,
    };
  }

  // Get daily summary for a specific date
  Future<DailySummary> getDailySummary(String date) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ? as date,
        SUM(CASE WHEN transaction_type = 'sale' THEN sales ELSE 0 END) as total_sales,
        SUM(cash) as total_cash,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_payment,
        SUM(total_received) as total_received,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
        SUM(total_received) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
      FROM transactions
      WHERE date = ?
    ''', [date, date]);
    
    // Get digital payment totals
    final List<Map<String, dynamic>> digitalMaps = await db.rawQuery('''
      SELECT 
        method,
        SUM(amount) as total_amount
      FROM payment_methods pm
      JOIN transactions t ON pm.transaction_id = t.id
      WHERE t.date = ?
      GROUP BY method
    ''', [date]);
    
    // If no data for this date, return zeros
    if (maps.isEmpty || maps.first['total_sales'] == null) {
      return DailySummary(
        date: date,
        totalSales: 0,
        totalCash: 0,
        totalPayment: 0,
        totalReceived: 0,
        totalOutstanding: 0,
        netCashFlow: 0,
        paymentMethods: {},
      );
    }
    
    // Create daily summary
    final summary = DailySummary.fromMap(maps.first);
    
    // Add all payment methods dynamically
    Map<String, double> paymentMethods = {};
    
    for (var map in digitalMaps) {
      final method = map['method'] as String;
      final amount = map['total_amount'] as double;
      paymentMethods[method] = amount;
    }
    
    // Add payment methods to summary
    summary.paymentMethods.addAll(paymentMethods);
    
    return summary;
  }

  // Get chart data for a specific date
  Future<Map<String, dynamic>> getDailyCharts(String date) async {
    final db = await database;
    
    // Get payment method distribution
    final List<Map<String, dynamic>> paymentMaps = await db.rawQuery('''
      SELECT 
        pm.method,
        SUM(pm.amount) as total_amount
      FROM payment_methods pm
      JOIN transactions t ON pm.transaction_id = t.id
      WHERE t.date = ? AND t.transaction_type IN ('sale', 'repayment')
      GROUP BY pm.method
    ''', [date]);
    
    // Get cash total
    final List<Map<String, dynamic>> cashMaps = await db.rawQuery('''
      SELECT 
        SUM(cash) as cash_total
      FROM transactions
      WHERE date = ? AND cash > 0
    ''', [date]);
    
    final cashTotal = cashMaps.first['cash_total'] ?? 0;
    
    List<Map<String, dynamic>> paymentMethods = [];
    double totalPayments = cashTotal;
    
    // Add digital payment methods
    for (var map in paymentMaps) {
      totalPayments += map['total_amount'] as double;
    }
    
    if (totalPayments > 0) {
      // Add cash if present
      if (cashTotal > 0) {
        int percentage = (cashTotal / totalPayments * 100).round();
        paymentMethods.add({
          'method': 'Cash',
          'amount': cashTotal,
          'percentage': percentage,
        });
      }
      
      // Add digital payment methods
      for (var map in paymentMaps) {
        int percentage = ((map['total_amount'] as double) / totalPayments * 100).round();
        paymentMethods.add({
          'method': map['method'],
          'amount': map['total_amount'],
          'percentage': percentage,
        });
      }
    }
    
    // Get transaction type distribution
    final List<Map<String, dynamic>> typeMaps = await db.rawQuery('''
      SELECT 
        transaction_type,
        COUNT(*) as count
      FROM transactions
      WHERE date = ?
      GROUP BY transaction_type
    ''', [date]);
    
    List<Map<String, dynamic>> transactionTypes = [];
    int totalTransactions = 0;
    
    for (var map in typeMaps) {
      totalTransactions += map['count'] as int;
    }
    
    if (totalTransactions > 0) {
      for (var map in typeMaps) {
        int percentage = ((map['count'] as int) / totalTransactions * 100).round();
        transactionTypes.add({
          'type': map['transaction_type'],
          'count': map['count'],
          'percentage': percentage,
        });
      }
    }
    
    return {
      'payment_methods': paymentMethods,
      'transaction_types': transactionTypes,
    };
  }

  // Get list of all daily reports
  Future<List<Map<String, dynamic>>> getDailyReports({
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        date,
        SUM(CASE WHEN transaction_type = 'sale' THEN sales ELSE 0 END) as total_sales,
        SUM(cash) + SUM(total_received) as total_received,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(total_received)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
      FROM transactions
    ''';
    
    List<String> conditions = [];
    List<dynamic> params = [];
    
    if (fromDate != null) {
      conditions.add('date >= ?');
      params.add(fromDate);
    }
    
    if (toDate != null) {
      conditions.add('date <= ?');
      params.add(toDate);
    }
    
    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' GROUP BY date ORDER BY date DESC';
    
    return await db.rawQuery(query, params);
  }

  // Get latest daily summary
  Future<Map<String, dynamic>?> getLatestSummary() async {
    final db = await database;
    
    // Get the latest date
    final List<Map<String, dynamic>> dateMaps = await db.rawQuery(
      'SELECT MAX(date) as latest_date FROM transactions'
    );
    
    final latestDate = dateMaps.first['latest_date'];
    if (latestDate == null) return null;
    
    // Get summary for the latest date
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ? as date,
        SUM(CASE WHEN transaction_type = 'sale' THEN sales ELSE 0 END) as total_sales,
        SUM(cash) + SUM(total_received) as total_received,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(total_received)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
      FROM transactions
      WHERE date = ?
    ''', [latestDate, latestDate]);
    
    if (maps.isEmpty) return null;
    
    return maps.first;
  }

  // Get summary statistics for a date range
  Future<Map<String, dynamic>> getSummaryStats({
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT 
        SUM(CASE WHEN transaction_type = 'sale' THEN sales ELSE 0 END) as total_sales,
        SUM(cash) + SUM(total_received) as total_received,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(total_received)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
      FROM transactions
    ''';
    
    List<String> conditions = [];
    List<dynamic> params = [];
    
    if (fromDate != null) {
      conditions.add('date >= ?');
      params.add(fromDate);
    }
    
    if (toDate != null) {
      conditions.add('date <= ?');
      params.add(toDate);
    }
    
    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, params);
    
    // Get total outstanding (current)
    final List<Map<String, dynamic>> outstandingMaps = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) -
        SUM(CASE WHEN transaction_type = 'repayment' THEN total_received ELSE 0 END) as total_outstanding
      FROM transactions
    ''');
    
    final stats = maps.first;
    stats['total_outstanding'] = outstandingMaps.first['total_outstanding'] ?? 0;
    
    // Add date range to response
    stats['date_range'] = {
      'from': fromDate ?? 'all',
      'to': toDate ?? 'all',
    };
    
    return stats;
  }

  // Get chart data for reports
  Future<Map<String, dynamic>> getChartData({
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;
    
    // Determine date range
    if (fromDate == null) {
      final List<Map<String, dynamic>> minDateMaps = await db.rawQuery(
        'SELECT MIN(date) as min_date FROM transactions'
      );
      fromDate = minDateMaps.first['min_date'];
    }
    
    if (toDate == null) {
      final List<Map<String, dynamic>> maxDateMaps = await db.rawQuery(
        'SELECT MAX(date) as max_date FROM transactions'
      );
      toDate = maxDateMaps.first['max_date'];
    }
    
    if (fromDate == null || toDate == null) {
      return {
        'dates': [],
        'sales': [],
        'received': [],
        'expenses': [],
        'outstanding': [],
        'net_cash_flow': [],
      };
    }
    
    // Get all dates in range
    List<String> dateRange = [];
    DateTime startDate = DateFormat('yyyy-MM-dd').parse(fromDate);
    DateTime endDate = DateFormat('yyyy-MM-dd').parse(toDate);
    
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      dateRange.add(DateFormat('yyyy-MM-dd').format(currentDate));
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    // Get data for each date
    List<String> dates = [];
    List<double> sales = [];
    List<double> received = [];
    List<double> expenses = [];
    List<double> outstanding = [];
    List<double> netCashFlow = [];
    
    for (String date in dateRange) {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN transaction_type = 'sale' THEN sales ELSE 0 END) as total_sales,
          SUM(cash) + SUM(total_received) as total_received,
          SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
          SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
          (SUM(cash) + SUM(total_received)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
        FROM transactions
        WHERE date = ?
      ''', [date]);
      
      final row = maps.first;
      
      dates.add(date);
      sales.add(row['total_sales'] ?? 0);
      received.add(row['total_received'] ?? 0);
      expenses.add(row['total_expenses'] ?? 0);
      outstanding.add(row['total_outstanding'] ?? 0);
      netCashFlow.add(row['net_cash_flow'] ?? 0);
    }
    
    return {
      'dates': dates,
      'sales': sales,
      'received': received,
      'expenses': expenses,
      'outstanding': outstanding,
      'net_cash_flow': netCashFlow,
    };
  }
}
