import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeFilter extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  
  const DateRangeFilter({
    Key? key,
    this.fromDate,
    this.toDate,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  _DateRangeFilterState createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateTime? _fromDate;
  DateTime? _toDate;
  
  @override
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
  }
  
  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
      widget.onDateRangeChanged(_fromDate, _toDate);
    }
  }
  
  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
      widget.onDateRangeChanged(_fromDate, _toDate);
    }
  }
  
  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    widget.onDateRangeChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From Date',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectFromDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: _fromDate != null
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To Date',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectToDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _toDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: _toDate != null
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_fromDate != null || _toDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearDates,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Dates'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
