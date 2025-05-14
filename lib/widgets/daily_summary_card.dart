import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/screens/daily_report_screen.dart';

class DailySummaryCard extends StatefulWidget {
  const DailySummaryCard({Key? key}) : super(key: key);

  @override
  _DailySummaryCardState createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestSummary();
  }

  Future<void> _loadLatestSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await Provider.of<DatabaseProvider>(context, listen: false).getLatestSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading latest summary: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _isLoading ? _buildLoadingIndicator() : _buildSummaryContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Daily Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_summary != null)
              Text(
                'For ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_summary!['date']))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        if (_summary != null)
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyReportScreen(
                    date: _summary!['date'],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 10),
            label: const Text('View Details'),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSummaryContent() {
    if (_summary == null) {
      return _buildNoSummaryContent();
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryItem(
          label: 'Sales',
          value: '₹${NumberFormat('#,##,###.##').format(_summary!['total_sales'] ?? 0)}',
        ),
        _SummaryItem(
          label: 'Received',
          value: '₹${NumberFormat('#,##,###.##').format(_summary!['total_received'] ?? 0)}',
        ),
        _SummaryItem(
          label: 'Outstanding',
          value: '₹${NumberFormat('#,##,###.##').format(_summary!['total_outstanding'] ?? 0)}',
        ),
        _SummaryItem(
          label: 'Expenses',
          value: '₹${NumberFormat('#,##,###.##').format(_summary!['total_expenses'] ?? 0)}',
        ),
        _SummaryItem(
          label: 'Net Cash Flow',
          value: '₹${NumberFormat('#,##,###.##').format(_summary!['net_cash_flow'] ?? 0)}',
          valueColor: (_summary!['net_cash_flow'] ?? 0) >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildNoSummaryContent() {
    return Center(
      child: Column(
        children: [
          const Text('Upload your first daily report to see summary statistics'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/upload');
            },
            child: const Text('Upload Report'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
