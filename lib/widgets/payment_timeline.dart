import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:credit_tracker/providers/database_provider.dart';

class PaymentTimeline extends StatefulWidget {
  final String customerName;
  
  const PaymentTimeline({
    Key? key,
    required this.customerName,
  }) : super(key: key);

  @override
  _PaymentTimelineState createState() => _PaymentTimelineState();
}

class _PaymentTimelineState extends State<PaymentTimeline> {
  List<Map<String, dynamic>> _timelineData = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }
  
  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await Provider.of<DatabaseProvider>(context, listen: false)
          .getCreditTimeline(widget.customerName);
      
      setState(() {
        _timelineData = List<Map<String, dynamic>>.from(data['timeline']);
        _paymentMethods = List<Map<String, dynamic>>.from(data['payment_methods']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading timeline data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Payment Timeline Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Timeline',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visualizing credit balance over time',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _timelineData.isEmpty
                            ? const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text('No timeline data available'),
                                ),
                              )
                            : SizedBox(
                                height: 300,
                                child: Center(
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
                                        'Chart visualization would appear here',
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
                                        '${_timelineData.length} data points available',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Credit Health Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credit Health Indicators',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Payment consistency and behavior metrics',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        
                        // Payment Consistency Score
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Consistency Score',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '7/10',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.7,
                                backgroundColor: Colors.grey[300],
                                color: Theme.of(context).primaryColor,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Based on payment regularity and completeness',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Average Days to Pay
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Average Days to Pay',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '15 days',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.85,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Average time between sale and payment',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Payment Method Breakdown
                        Text(
                          'Payment Method Breakdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _paymentMethods.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No payment method data available'),
                                ),
                              )
                            : Row(
                                children: _paymentMethods.map((method) {
                                  return Expanded(
                                    child: Card(
                                      color: Theme.of(context).colorScheme.surface,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${method['percentage']}%',
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              method['method'],
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
