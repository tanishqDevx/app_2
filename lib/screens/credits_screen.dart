import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  String _sortBy = 'days';

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
        _sortCredits();
        _filterCredits(_searchQuery);
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

  void _sortCredits() {
    switch (_sortBy) {
      case 'name':
        _credits.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case 'amount':
        _credits.sort((a, b) => b.totalOutstanding.compareTo(a.totalOutstanding));
        break;
      case 'days':
        _credits.sort((a, b) => b.daysOutstanding.compareTo(a.daysOutstanding));
        break;
      case 'date':
        _credits.sort((a, b) => b.lastDate.compareTo(a.lastDate));
        break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Credits'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortCredits();
                _filterCredits(_searchQuery);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Sort by Amount'),
              ),
              const PopupMenuItem(
                value: 'days',
                child: Text('Sort by Days Outstanding'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Last Activity'),
              ),
            ],
          ),
        ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredCredits.length,
                          itemBuilder: (context, index) {
                            final credit = _filteredCredits[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreditDetailScreen(
                                      customerName: credit.customerName,
                                    ),
                                  ),
                                ).then((_) => _loadCredits());
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            credit.customerName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '₹${NumberFormat('#,##,###.##').format(credit.totalOutstanding)}',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green[800],
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last Paid: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(credit.lastDate))}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(thickness: 1),
                                  ],
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
