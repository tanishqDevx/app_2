import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/models/transaction.dart';

class TransactionList extends StatefulWidget {
  final String? customerName;
  final String? date;
  
  const TransactionList({
    Key? key,
    this.customerName,
    this.date,
  }) : super(key: key);

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _transactionType = 'all';
  
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
      List<Transaction> transactions;
      
      if (widget.customerName != null) {
        transactions = await Provider.of<DatabaseProvider>(context, listen: false)
            .getTransactionsByCustomer(widget.customerName!);
      } else if (widget.date != null) {
        transactions = await Provider.of<DatabaseProvider>(context, listen: false)
            .getTransactionsByDate(widget.date!);
      } else {
        transactions = await Provider.of<DatabaseProvider>(context, listen: false).getTransactions();
      }
      
      setState(() {
        _transactions = transactions;
        _filterTransactions();
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
  
  void _filterTransactions() {
    if (_transactionType == 'all') {
      // No filtering needed
      return;
    }
    
    setState(() {
      _transactions = _transactions.where((transaction) {
        return transaction.transactionType == _transactionType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter dropdown
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.customerName != null
                      ? 'Transaction History'
                      : widget.date != null
                          ? 'Daily Transactions'
                          : 'All Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _transactionType,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
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
              ),
            ],
          ),
        ),
        
        // Transactions list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.customerName != null
                                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction.date))
                                            : transaction.customerName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTransactionTypeColor(transaction.transactionType).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getTransactionTypeLabel(transaction.transactionType),
                                        style: TextStyle(
                                          color: _getTransactionTypeColor(transaction.transactionType),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Transaction details
                                if (transaction.sales > 0) ...[
                                  _TransactionDetail(
                                    label: 'Sales',
                                    value: '₹${NumberFormat('#,##,###.##').format(transaction.sales)}',
                                  ),
                                ],
                                
                                if (transaction.cash > 0 || transaction.hdfc > 0 || transaction.gpay > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Received:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (transaction.cash > 0)
                                    _TransactionDetail(
                                      label: 'Cash',
                                      value: '₹${NumberFormat('#,##,###.##').format(transaction.cash)}',
                                      valueColor: Colors.green[700],
                                    ),
                                  if (transaction.hdfc > 0)
                                    _TransactionDetail(
                                      label: 'HDFC',
                                      value: '₹${NumberFormat('#,##,###.##').format(transaction.hdfc)}',
                                      valueColor: Colors.green[700],
                                    ),
                                  if (transaction.gpay > 0)
                                    _TransactionDetail(
                                      label: 'GPay',
                                      value: '₹${NumberFormat('#,##,###.##').format(transaction.gpay)}',
                                      valueColor: Colors.green[700],
                                    ),
                                ],
                                
                                if (transaction.payment > 0) ...[
                                  const SizedBox(height: 8),
                                  _TransactionDetail(
                                    label: 'Expense',
                                    value: '₹${NumberFormat('#,##,###.##').format(transaction.payment)}',
                                    valueColor: Colors.red[700],
                                  ),
                                ],
                                
                                if (transaction.outstanding > 0) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  _TransactionDetail(
                                    label: 'Outstanding',
                                    value: '₹${NumberFormat('#,##,###.##').format(transaction.outstanding)}',
                                    valueColor: Colors.orange[700],
                                    isBold: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.blue;
      case 'repayment':
        return Colors.green;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'SALE';
      case 'repayment':
        return 'REPAYMENT';
      case 'expense':
        return 'EXPENSE';
      default:
        return type.toUpperCase();
    }
  }
}

class _TransactionDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  
  const _TransactionDetail({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
