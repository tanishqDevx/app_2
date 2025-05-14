import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:intl/intl.dart';

class SummaryCharts extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  
  const SummaryCharts({
    Key? key,
    this.fromDate,
    this.toDate,
  }) : super(key: key);

  @override
  _SummaryChartsState createState() => _SummaryChartsState();
}

class _SummaryChartsState extends State<SummaryCharts> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _chartData;
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadChartData();
  }
  
  @override
  void didUpdateWidget(SummaryCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromDate != oldWidget.fromDate || widget.toDate != oldWidget.toDate) {
      _loadChartData();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fromDateStr = widget.fromDate != null ? DateFormat('yyyy-MM-dd').format(widget.fromDate!) : null;
      final toDateStr = widget.toDate != null ? DateFormat('yyyy-MM-dd').format(widget.toDate!) : null;
      
      final chartData = await Provider.of<DatabaseProvider>(context, listen: false).getChartData(
        fromDate: fromDateStr,
        toDate: toDateStr,
      );
      
      setState(() {
        _chartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chart data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Received'),
            Tab(text: 'Expenses'),
            Tab(text: 'Outstanding'),
            Tab(text: 'Cash Flow'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chartData == null || (_chartData!['dates'] as List).isEmpty
                  ? const Center(
                      child: Text('No chart data available for the selected date range'),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChartPlaceholder('Sales', 'Line chart'),
                        _buildChartPlaceholder('Received payments', 'Line chart'),
                        _buildChartPlaceholder('Expenses', 'Bar chart'),
                        _buildChartPlaceholder('Outstanding credits', 'Line chart'),
                        _buildChartPlaceholder('Net cash flow', 'Area chart'),
                      ],
                    ),
        ),
      ],
    );
  }
  
  Widget _buildChartPlaceholder(String title, String chartType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '$chartType visualization would appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Using FL Chart in a real implementation',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            '$title over time: ${(_chartData!['dates'] as List).length} data points',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}