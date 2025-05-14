import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/screens/daily_report_screen.dart';

class DailyReportsList extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  
  const DailyReportsList({
    Key? key,
    this.fromDate,
    this.toDate,
  }) : super(key: key);

  @override
  _DailyReportsListState createState() => _DailyReportsListState();
}

class _DailyReportsListState extends State<DailyReportsList> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadReports();
  }
  
  @override
  void didUpdateWidget(DailyReportsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromDate != oldWidget.fromDate || widget.toDate != oldWidget.toDate) {
      _loadReports();
    }
  }
  
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fromDateStr = widget.fromDate != null ? DateFormat('yyyy-MM-dd').format(widget.fromDate!) : null;
      final toDateStr = widget.toDate != null ? DateFormat('yyyy-MM-dd').format(widget.toDate!) : null;
      
      final reports = await Provider.of<DatabaseProvider>(context, listen: false).getDailyReports(
        fromDate: fromDateStr,
        toDate: toDateStr,
      );
      
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _reports.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No daily reports found for the selected date range'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  final date = report['date'] as String;
                  final totalSales = report['total_sales'] as double? ?? 0;
                  final totalReceived = report['total_received'] as double? ?? 0;
                  final netCashFlow = report['net_cash_flow'] as double? ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.calendar_today),
                      ),
                      title: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(date))),
                      subtitle: Text(
                        'Sales: ₹${NumberFormat('#,##,###').format(totalSales)} • Received: ₹${NumberFormat('#,##,###').format(totalReceived)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${NumberFormat('#,##,###').format(netCashFlow)}',
                            style: TextStyle(
                              color: netCashFlow >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Net Cash Flow', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyReportScreen(date: date),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
  }
}