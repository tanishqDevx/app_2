class Credit {
  final String customerName;
  final double totalOutstanding;
  final String firstDate;
  final String lastDate;
  final int daysOutstanding;
  final String status;

  Credit({
    required this.customerName,
    required this.totalOutstanding,
    required this.firstDate,
    required this.lastDate,
    required this.daysOutstanding,
    required this.status,
  });

  factory Credit.fromMap(Map<String, dynamic> map) {
    // Calculate status based on days outstanding
    String status;

    // Safely handle 'days_outstanding' as either int or double
    final days = (map['days_outstanding'] is double)
        ? (map['days_outstanding'] as double).toInt() // If it's a double, convert to int
        : map['days_outstanding'] as int; // If it's already an int, use it as is

    if (days > 90) {
      status = 'Overdue';
    } else if (days > 30) {
      status = 'Warning';
    } else {
      status = 'Good';
    }
    return Credit(
      customerName: map['customer_name'],
      totalOutstanding: (map['total_outstanding'] as num).toDouble(),
      firstDate: map['first_date'],
      lastDate: map['last_date'],
      daysOutstanding: days,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'total_outstanding': totalOutstanding,
      'first_date': firstDate,
      'last_date': lastDate,
      'days_outstanding': daysOutstanding,
      'status': status,
    };
  }
}
