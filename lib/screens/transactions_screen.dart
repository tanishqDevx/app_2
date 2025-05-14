import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/models/transaction.dart';
import 'package:credit_tracker/widgets/date_range_filter.dart';
import 'package:credit_tracker/screens/credit_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _transactionType = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fromDateStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
      final toDateStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;
      
      final transactions = await Provider.of<DatabaseProvider>(context, listen: false).getTransactions(
        fromDate: fromDateStr,
        toDate: toDateStr,
        transactionType: _transactionType != 'all' ? _transactionType : null,
      );
      
      setState(() {
        _transactions = transactions;
        _applySearchFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((transaction) {
        return transaction.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }
  
  void _exportTransactions() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by customer name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearchFilter();
                });
              },
            ),
          ),
          
          if (_showFilters) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _transactionType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Transactions')),
                      DropdownMenuItem(value: 'sale', child: Text('Sales')),
                      DropdownMenuItem(value: 'repayment', child: Text('Repayments')),
                      DropdownMenuItem(value: 'expense', child: Text('Expenses')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value!;
                      });
                      _loadTransactions();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DateRangeFilter(
                    fromDate: _fromDate,
                    toDate: _toDate,
                    onDateRangeChanged: (from, to) {
                      setState(() {
                        _fromDate = from;
                        _toDate = to;
                      });
                      _loadTransactions();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(transaction.customerName),
                              subtitle: Text(
                                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction.date))} • ${transaction.transactionType.toUpperCase()}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (transaction.sales > 0)
                                    Text(
                                      '₹${NumberFormat('#,##,###.##').format(transaction.sales)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  if (transaction.totalReceived > 0)
                                    Text(
                                      'Received: ₹${NumberFormat('#,##,###.##').format(transaction.totalReceived)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (transaction.payment > 0)
                                    Text(
                                      'Expense: ₹${NumberFormat('#,##,###.##').format(transaction.payment)}',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreditDetailScreen(
                                      customerName: transaction.customerName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
