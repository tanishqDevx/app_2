class DailySummary {
  final String date;
  final double totalSales;
  final double totalCash;
  final double totalPayment;
  final double totalReceived;
  final double totalOutstanding;
  final double netCashFlow;
  final Map<String, double> paymentMethods;

  DailySummary({
    required this.date,
    required this.totalSales,
    required this.totalCash,
    required this.totalPayment,
    required this.totalReceived,
    required this.totalOutstanding,
    required this.netCashFlow,
    Map<String, double>? paymentMethods,
  }) : this.paymentMethods = paymentMethods ?? {};

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: map['date'],
      totalSales: map['total_sales'] ?? 0,
      totalCash: map['total_cash'] ?? 0,
      totalPayment: map['total_payment'] ?? 0,
      totalReceived: map['total_received'] ?? 0,
      totalOutstanding: map['total_outstanding'] ?? 0,
      netCashFlow: map['net_cash_flow'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_sales': totalSales,
      'total_cash': totalCash,
      'total_payment': totalPayment,
      'total_received': totalReceived,
      'total_outstanding': totalOutstanding,
      'net_cash_flow': netCashFlow,
      'payment_methods': paymentMethods,
    };
  }

  // For backward compatibility
  double get totalhdfc {
    for (var entry in paymentMethods.entries) {
      if (entry.key.toLowerCase().contains('hdfc') || 
          entry.key.toLowerCase().contains('kotak') ||
          entry.key.toLowerCase().contains('bank')) {
        return entry.value;
      }
    }
    return 0;
  }

  double get totalGpay {
    for (var entry in paymentMethods.entries) {
      if (entry.key.toLowerCase().contains('gpay') || 
          entry.key.toLowerCase().contains('google') ||
          entry.key.toLowerCase().contains('pay')) {
        return entry.value;
      }
    }
    return 0;
  }
}
