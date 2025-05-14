import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/models/credit.dart';
import 'package:credit_tracker/widgets/transaction_list.dart';
import 'package:credit_tracker/widgets/payment_timeline.dart';

class CreditDetailScreen extends StatefulWidget {
  final String customerName;
  
  const CreditDetailScreen({
    Key? key,
    required this.customerName,
  }) : super(key: key);

  @override
  _CreditDetailScreenState createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> with SingleTickerProviderStateMixin {
  Credit? _creditDetails;
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCreditDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCreditDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final creditDetails = await Provider.of<DatabaseProvider>(context, listen: false)
          .getCreditDetails(widget.customerName);
      
      setState(() {
        _creditDetails = creditDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading credit details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.red;
      case 'Warning':
        return Colors.orange;
      case 'Good':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export functionality coming soon')),
              );
            },
            tooltip: 'Export History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCreditDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _creditDetails == null
                ? const Center(child: Text('Customer not found'))
                : Column(
                    children: [
                      // Credit summary cards
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Outstanding Balance',
                                    value: '₹${NumberFormat('#,##,###.##').format(_creditDetails!.totalOutstanding)}',
                                    subtitle: 'Active since ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_creditDetails!.firstDate))}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Credit Status',
                                    value: _creditDetails!.status,
                                    valueColor: _getStatusColor(_creditDetails!.status),
                                    subtitle: _creditDetails!.status == 'Good'
                                        ? 'Payments are on schedule'
                                        : _creditDetails!.status == 'Warning'
                                            ? 'Payment overdue by 30+ days'
                                            : 'Payment overdue by 90+ days',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Last Activity',
                                    value: DateFormat('dd/MM/yyyy').format(DateTime.parse(_creditDetails!.lastDate)),
                                    subtitle: 'Outstanding for ${_creditDetails!.daysOutstanding} days',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Tabs
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Transactions'),
                          Tab(text: 'Payment Timeline'),
                        ],
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                      ),
                      
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            TransactionList(customerName: widget.customerName),
                            PaymentTimeline(customerName: widget.customerName),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;
  
  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
