import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/screens/upload_screen.dart';
import 'package:credit_tracker/screens/credits_screen.dart';
import 'package:credit_tracker/screens/transactions_screen.dart';
import 'package:credit_tracker/screens/reports_screen.dart';
import 'package:credit_tracker/widgets/dashboard_card.dart';
import 'package:credit_tracker/widgets/daily_summary_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Tracking Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Upload daily reports and track transactions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            
            // Dashboard cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DashboardCard(
                  title: 'Upload Report',
                  value: 'Daily XLSX',
                  description: 'Upload your daily transaction data',
                  icon: Icons.upload_file,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen()),
                  ),
                  buttonText: 'Upload File',
                ),
                DashboardCard(
                  title: 'View Credits',
                  value: 'Outstanding',
                  description: 'Track customer credits and payments',
                  icon: Icons.credit_card,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreditsScreen()),
                  ),
                  buttonText: 'View Credits',
                  buttonVariant: 'outline',
                ),
                DashboardCard(
                  title: 'Transactions',
                  value: 'All Records',
                  description: 'View all transaction history',
                  icon: Icons.receipt_long,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                  ),
                  buttonText: 'View Transactions',
                  buttonVariant: 'outline',
                ),
                DashboardCard(
                  title: 'Reports',
                  value: 'Analytics',
                  description: 'View reports and statistics',
                  icon: Icons.pie_chart,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  ),
                  buttonText: 'View Reports',
                  buttonVariant: 'outline',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Daily summary
            const DailySummaryCard(),
          ],
        ),
      ),
    );
  }
}
