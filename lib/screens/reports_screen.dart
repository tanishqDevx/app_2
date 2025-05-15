import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/widgets/date_range_filter.dart';
import 'package:credit_tracker/widgets/summary_charts.dart';
import 'package:credit_tracker/widgets/daily_reports_list.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _summaryStats;
  bool _isLoading = true;
  DateTime? _fromDate;
  DateTime? _toDate;
  
  @override
  void initState() {
    super.initState();
    _loadSummaryStats();
  }
  
  Future<void> _loadSummaryStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fromDateStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
      final toDateStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;
      
      final summaryStats = await Provider.of<DatabaseProvider>(context, listen: false).getSummaryStats(
        fromDate: fromDateStr,
        toDate: toDateStr,
      );
      
      setState(() {
        _summaryStats = summaryStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading summary statistics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummaryStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range filter
                DateRangeFilter(
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onDateRangeChanged: (from, to) {
                    setState(() {
                      _fromDate = from;
                      _toDate = to;
                    });
                    _loadSummaryStats();
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Summary cards
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _summaryStats == null
                        ? const Center(
                            child: Text('No data available'),
                          )
                        : Column(
                            children: [
                              // Summary cards grid
                              GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _SummaryCard(
                                    title: 'Total Sales',
                                    value: '₹${NumberFormat('#,##,###.##').format(_summaryStats!['total_sales'] ?? 0)}',
                                    subtitle: 'Gross sales amount',
                                  ),
                                  _SummaryCard(
                                    title: 'Total Received',
                                    value: '₹${NumberFormat('#,##,###.##').format(_summaryStats!['total_received'] ?? 0)}',
                                    subtitle: 'Cash + hdfc + GPay',
                                  ),
                                  _SummaryCard(
                                    title: 'Outstanding',
                                    value: '₹${NumberFormat('#,##,###.##').format(_summaryStats!['total_outstanding'] ?? 0)}',
                                    subtitle: 'Credit given to customers',
                                  ),
                                  _SummaryCard(
                                    title: 'Expenses',
                                    value: '₹${NumberFormat('#,##,###.##').format(_summaryStats!['total_expenses'] ?? 0)}',
                                    subtitle: 'Total expenses',
                                  ),
                                  _SummaryCard(
                                    title: 'Net Cash Flow',
                                    value: '₹${NumberFormat('#,##,###.##').format(_summaryStats!['net_cash_flow'] ?? 0)}',
                                    subtitle: 'Received - Expenses',
                                    valueColor: (_summaryStats!['net_cash_flow'] ?? 0) >= 0 ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                
                const SizedBox(height: 24),
                
                // Charts
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary Charts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visual representation of your financial data',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        SummaryCharts(
                          fromDate: _fromDate,
                          toDate: _toDate,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Daily reports list
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reports',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View detailed reports for each day',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        DailyReportsList(
                          fromDate: _fromDate,
                          toDate: _toDate,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
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
