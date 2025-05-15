import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/widgets/transaction_list.dart';
// import 'package:credit_tracker/widgets/daily_charts.dart';

class DailyReportScreen extends StatefulWidget {
  final String date;
  
  const DailyReportScreen({Key? key, required this.date}) : super(key: key);

  @override
  _DailyReportScreenState createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Report: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.date))}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export functionality coming soon')),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder(
              future: Provider.of<DatabaseProvider>(context, listen: false)
                  .getDailySummary(widget.date),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: Text('No data available for this date'));
                }
                
                final summary = snapshot.data!;
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Sales',
                            value: '₹${NumberFormat('#,##,###.##').format(summary.totalSales)}',
                            subtitle: 'Gross sales amount',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Received',
                            value: '₹${NumberFormat('#,##,###.##').format(summary.totalReceived)}',
                            subtitle: 'All payment methods',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Outstanding',
                            value: '₹${NumberFormat('#,##,###.##').format(summary.totalOutstanding)}',
                            subtitle: 'New credit given today',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Net Cash Flow',
                            value: '₹${NumberFormat('#,##,###.##').format(summary.netCashFlow)}',
                            valueColor: summary.netCashFlow >= 0 ? Colors.green : Colors.red,
                            subtitle: 'Received - Expenses',
                          ),
                        ),
                      ],
                    ),
                    
                    // Payment Methods Breakdown
                    if (summary.paymentMethods.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Methods',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ...summary.paymentMethods.entries.map((entry) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(
                                        '₹${NumberFormat('#,##,###.##').format(entry.value)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ).toList(),
                              if (summary.totalCash > 0) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cash'),
                                      Text(
                                        '₹${NumberFormat('#,##,###.##').format(summary.totalCash)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Charts'),
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
                TransactionList(date: widget.date),
                Center(child: Text('Charts coming soon')), // Placeholder for charts
              ],
            ),
          ),
        ],
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
