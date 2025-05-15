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
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: 0.75,  // Made cards even taller (was 0.85)
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                DashboardCard(
                  title: 'Upload',
                  value: 'Daily XLSX',
                  description: 'Upload your daily\ntransaction data',
                  icon: Icons.upload_file,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen()),
                  ),
                  buttonText: 'Upload',
                ),
                DashboardCard(
                  title: 'Credits',
                  value: 'Outstanding',
                  description: 'Track customer\ncredits', // Line break for better fit
                  icon: Icons.credit_card,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreditsScreen()),
                  ),
                  buttonText: 'View',
                  buttonVariant: 'outline',
                ),
                DashboardCard(
                  title: 'History',  // Shortened from 'Transactions'
                  value: 'Records',  // Shortened from 'All Records'
                  description: 'View transaction\nhistory', // Line break for better fit
                  icon: Icons.receipt_long,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                  ),
                  buttonText: 'View',
                  buttonVariant: 'outline',
                ),
                DashboardCard(
                  title: 'Reports',
                  value: 'Analytics',
                  description: 'View reports and\nstatistics', // Line break for better fit
                  icon: Icons.pie_chart,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  ),
                  buttonText: 'View',
                  buttonVariant: 'outline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
