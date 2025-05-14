import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:credit_tracker/providers/database_provider.dart';
import 'package:credit_tracker/models/credit.dart';
import 'package:credit_tracker/screens/credit_detail_screen.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({Key? key}) : super(key: key);

  @override
  _CreditsScreenState createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  List<Credit> _credits = [];
  List<Credit> _filteredCredits = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credits = await Provider.of<DatabaseProvider>(context, listen: false).getCredits();
      setState(() {
        _credits = credits;
        _filteredCredits = credits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading credits: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterCredits(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredCredits = _credits;
      } else {
        _filteredCredits = _credits.where((credit) {
          return credit.customerName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
        title: const Text('Outstanding Credits'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCredits,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _filterCredits,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCredits.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No outstanding credits found'
                                : 'No results found for "$_searchQuery"',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredCredits.length,
                          itemBuilder: (context, index) {
                            final credit = _filteredCredits[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreditDetailScreen(
                                        customerName: credit.customerName,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          credit.customerName,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        )
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${NumberFormat('#,##,###.##').format(credit.totalOutstanding)}',
                                            style: TextStyle(
                                              color: _getStatusColor(credit.status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Last Paid: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(credit.lastDate))}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
