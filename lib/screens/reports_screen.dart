import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/widgets/date_range_filter.dart';
import 'package:credit_tracker/widgets/daily_reports_list.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
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
                  },
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
