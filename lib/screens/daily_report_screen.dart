import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/widgets/transaction_list.dart';

class DailyReportScreen extends StatelessWidget {
  final String date;

  const DailyReportScreen({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Report: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date))}'),
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
      body: FutureBuilder(
        future: Provider.of<DatabaseProvider>(context, listen: false).getDailySummary(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available for this date'));
          }

          final summary = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards - No Expanded
                Row(
                  children: [
                    Flexible(
                      child: _SummaryCard(
                        title: 'Total Sales',
                        value: '₹${NumberFormat('#,##,###.##').format(summary.totalSales)}',
                        subtitle: 'Gross sales',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _SummaryCard(
                        title: 'Outstanding',
                        value: '₹${NumberFormat('#,##,###.##').format(summary.totalOutstanding)}',
                        subtitle: 'Credit given',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Methods
                if (summary.paymentMethods.isNotEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Methods', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...summary.paymentMethods.entries.map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                              )),
                          if (summary.totalCash > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cash'),
                                Text(
                                  '₹${NumberFormat('#,##,###.##').format(summary.totalCash)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Transactions section
                Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                // Constrain height to avoid layout issues
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TransactionList(
                    date: date,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
