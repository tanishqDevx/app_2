
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
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        sales REAL DEFAULT 0,
        cash REAL DEFAULT 0,
        hdfc REAL DEFAULT 0,
        gpay REAL DEFAULT 0,
        payment REAL DEFAULT 0,
        transaction_type TEXT CHECK(transaction_type IN ('sale', 'repayment', 'expense')),
        outstanding REAL DEFAULT 0,
        related_credit_id INTEGER,
        FOREIGN KEY (related_credit_id) REFERENCES transactions(id)
      )
    ''');
    
    // Create indexes for faster lookups
    await db.execute('CREATE INDEX idx_customer_name ON transactions(customer_name)');
    await db.execute('CREATE INDEX idx_date ON transactions(date)');
  }

  Future<void> init() async {
    await database;
  }

  Future<Map<String, dynamic>> processExcelFile(File file, String date) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    final db = await database;
    int rowsProcessed = 0;
    
    await db.transaction((txn) async {
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]!.rows;
      
      if (rows.length < 3) throw Exception('Excel file does not have enough rows');
      
      final headerRow = rows[1];
      Map<String, int> columnIndexes = {};
      
      for (int i = 0; i < headerRow.length; i++) {
        final cell = headerRow[i];
        if (cell == null) continue;
        final value = cell.value.toString().toLowerCase();
        columnIndexes[value] = i;
        
        if (value.contains('particular')) columnIndexes['particulars'] = i;
        else if (value.contains('sale')) columnIndexes['sales'] = i;
        else if (value.contains('payment')) columnIndexes['payment'] = i;
      }
      
      if (!columnIndexes.containsKey('particulars')) throw Exception('Could not find "Particulars" column');
      if (!columnIndexes.containsKey('sales')) throw Exception('Could not find "SALES" column');
      if (!columnIndexes.containsKey('payment')) throw Exception('Could not find "PAYMENT" column');
      
      final salesIndex = columnIndexes['sales']!;
      final paymentIndex = columnIndexes['payment']!;
      
      List<Map<String, dynamic>> paymentColumns = [];
      for (int i = salesIndex + 1; i < paymentIndex; i++) {
        if (i >= headerRow.length) continue;
        var cell = headerRow[i];
        if (cell == null || cell.value == null) continue;
        String methodName = cell.value.toString().trim().toLowerCase();
        paymentColumns.add({'index': i, 'name': methodName});
      }
      
      for (int i = 2; i < rows.length - 2; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= columnIndexes['particulars']!) continue;
        
        final nameCell = row[columnIndexes['particulars']!];
        if (nameCell == null || nameCell.value.toString().trim().isEmpty) continue;
        
        final customerName = nameCell.value.toString().trim();
        
        if (customerName.toLowerCase().contains('manoj ji') || 
            customerName.toLowerCase().contains('cashin office')) continue;
        if (customerName.toLowerCase().contains('total')) continue;
        
        final sales = _getCellNumericValue(row, salesIndex);
        final payment = _getCellNumericValue(row, paymentIndex);
        
        double cash = 0, hdfc = 0, gpay = 0;
        for (var pc in paymentColumns) {
          double amount = _getCellNumericValue(row, pc['index']);
          String name = pc['name'];
          
          if (name.contains('cash')) {
            cash += amount;
          } else if (name.contains('hdfc') || name.contains('kotak') || name.contains('esco')) {
            hdfc += amount;
          } else if (name.contains('g pay') || name.contains('gpay') || name.contains('google')) {
            gpay += amount;
          }
        }
        
        final received = cash + hdfc + gpay;
        if (sales == 0 && received == 0 && payment == 0) continue;
        
        String transactionType;
        double outstanding = 0;
        
        if (sales > 0) {
          transactionType = 'sale';
          outstanding = sales - received;
        } else if (received > 0) {
          transactionType = 'repayment';
        } else if (payment > 0) {
          transactionType = 'expense';
        } else {
          continue;
        }
        
        await txn.insert('transactions', {
          'date': date,
          'customer_name': customerName,
          'sales': sales,
          'cash': cash,
          'hdfc': hdfc,
          'gpay': gpay,
          'payment': payment,
          'transaction_type': transactionType,
          'outstanding': outstanding,
        });
        
        rowsProcessed++;
      }
    });
    
    notifyListeners();
    return {'status': 'success', 'rows_processed': rowsProcessed, 'date': date};
  }
  // Helper method to get numeric value from cell
  double _getCellNumericValue(List<dynamic> row, int index) {
    if (index >= row.length || row[index] == null) return 0;
    final cell = row[index];
    if (cell.value is num) return (cell.value as num).toDouble();
    try {
      return double.parse(cell.value.toString().replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  // Get all transactions
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
    
    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  // Get transactions by date
  Future<List<model.Transaction>> getTransactionsByDate(String date) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
    
    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  // Get transactions by customer
  Future<List<model.Transaction>> getTransactionsByCustomer(String customerName) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'customer_name = ?',
      whereArgs: [customerName],
      orderBy: 'date DESC, id DESC',
    );
    
    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  // Get all credits (customers with outstanding balances)
  Future<List<Credit>> getCredits() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        customer_name,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) -
        SUM(CASE WHEN transaction_type = 'repayment' THEN (cash + hdfc + gpay) ELSE 0 END) as total_outstanding,
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
        SUM(CASE WHEN transaction_type = 'repayment' THEN (cash + hdfc + gpay) ELSE 0 END) as total_outstanding,
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
        SUM(CASE WHEN transaction_type = 'repayment' THEN (cash + hdfc + gpay) ELSE 0 END) as balance
      FROM transactions
      WHERE customer_name = ?
      GROUP BY date
      ORDER BY date
    ''', [customerName]);
    
    // Get payment method breakdown
    final List<Map<String, dynamic>> paymentMaps = await db.rawQuery('''
      SELECT 
        SUM(cash) as cash_total,
        SUM(hdfc) as hdfc_total,
        SUM(gpay) as gpay_total
      FROM transactions
      WHERE customer_name = ? AND (cash > 0 OR hdfc > 0 OR gpay > 0)
    ''', [customerName]);
    
    final paymentTotals = paymentMaps.first;
    
    List<Map<String, dynamic>> paymentMethods = [];
    double totalPayments = (paymentTotals['cash_total'] ?? 0) + 
                          (paymentTotals['hdfc_total'] ?? 0) + 
                          (paymentTotals['gpay_total'] ?? 0);
    
    if (totalPayments > 0) {
      for (var entry in [
        {'method': 'Cash', 'amount': paymentTotals['cash_total'] ?? 0},
        {'method': 'HDFC', 'amount': paymentTotals['hdfc_total'] ?? 0},
        {'method': 'GPay', 'amount': paymentTotals['gpay_total'] ?? 0},
      ]) {
        if (entry['amount'] > 0) {
          int percentage = ((entry['amount'] as double) / totalPayments * 100).round();
          paymentMethods.add({
            'method': entry['method'],
            'percentage': percentage,
          });
        }
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
        SUM(hdfc) as total_hdfc,
        SUM(gpay) as total_gpay,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_payment,
        SUM(cash) + SUM(hdfc) + SUM(gpay) as total_received,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
        (SUM(cash) + SUM(hdfc) + SUM(gpay)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
      FROM transactions
      WHERE date = ?
    ''', [date, date]);
    
    // If no data for this date, return zeros
    if (maps.isEmpty || maps.first['total_sales'] == null) {
      return DailySummary(
        date: date,
        totalSales: 0,
        totalCash: 0,
        totalHdfc: 0,
        totalGpay: 0,
        totalPayment: 0,
        totalReceived: 0,
        totalOutstanding: 0,
        netCashFlow: 0,
      );
    }
    
    return DailySummary.fromMap(maps.first);
  }

  // Get chart data for a specific date
  Future<Map<String, dynamic>> getDailyCharts(String date) async {
    final db = await database;
    
    // Get payment method distribution
    final List<Map<String, dynamic>> paymentMaps = await db.rawQuery('''
      SELECT 
        SUM(cash) as cash_total,
        SUM(hdfc) as hdfc_total,
        SUM(gpay) as gpay_total
      FROM transactions
      WHERE date = ? AND (cash > 0 OR hdfc > 0 OR gpay > 0)
    ''', [date]);
    
    final paymentTotals = paymentMaps.first;
    
    List<Map<String, dynamic>> paymentMethods = [];
    double totalPayments = (paymentTotals['cash_total'] ?? 0) + 
                          (paymentTotals['hdfc_total'] ?? 0) + 
                          (paymentTotals['gpay_total'] ?? 0);
    
    if (totalPayments > 0) {
      for (var entry in [
        {'method': 'Cash', 'amount': paymentTotals['cash_total'] ?? 0},
        {'method': 'HDFC', 'amount': paymentTotals['hdfc_total'] ?? 0},
        {'method': 'GPay', 'amount': paymentTotals['gpay_total'] ?? 0},
      ]) {
        if (entry['amount'] > 0) {
          int percentage = ((entry['amount'] as double) / totalPayments * 100).round();
          paymentMethods.add({
            'method': entry['method'],
            'amount': entry['amount'],
            'percentage': percentage,
          });
        }
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
        SUM(cash) + SUM(hdfc) + SUM(gpay) as total_received,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(hdfc) + SUM(gpay)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
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
        SUM(cash) + SUM(hdfc) + SUM(gpay) as total_received,
        SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(hdfc) + SUM(gpay)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
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
        SUM(cash) + SUM(hdfc) + SUM(gpay) as total_received,
        SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
        (SUM(cash) + SUM(hdfc) + SUM(gpay)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
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
        SUM(CASE WHEN transaction_type = 'repayment' THEN (cash + hdfc + gpay) ELSE 0 END) as total_outstanding
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
          SUM(cash) + SUM(hdfc) + SUM(gpay) as total_received,
          SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as total_expenses,
          SUM(CASE WHEN transaction_type = 'sale' THEN outstanding ELSE 0 END) as total_outstanding,
          (SUM(cash) + SUM(hdfc) + SUM(gpay)) - SUM(CASE WHEN transaction_type = 'expense' THEN payment ELSE 0 END) as net_cash_flow
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
