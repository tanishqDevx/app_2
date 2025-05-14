class DailySummary {
  final String date;
  final double totalSales;
  final double totalCash;
  final double totalHdfc;
  final double totalGpay;
  final double totalPayment;
  final double totalReceived;
  final double totalOutstanding;
  final double netCashFlow;

  DailySummary({
    required this.date,
    required this.totalSales,
    required this.totalCash,
    required this.totalHdfc,
    required this.totalGpay,
    required this.totalPayment,
    required this.totalReceived,
    required this.totalOutstanding,
    required this.netCashFlow,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: map['date'],
      totalSales: map['total_sales'],
      totalCash: map['total_cash'],
      totalHdfc: map['total_hdfc'],
      totalGpay: map['total_gpay'],
      totalPayment: map['total_payment'],
      totalReceived: map['total_received'],
      totalOutstanding: map['total_outstanding'],
      netCashFlow: map['net_cash_flow'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_sales': totalSales,
      'total_cash': totalCash,
      'total_hdfc': totalHdfc,
      'total_gpay': totalGpay,
      'total_payment': totalPayment,
      'total_received': totalReceived,
      'total_outstanding': totalOutstanding,
      'net_cash_flow': netCashFlow,
    };
  }
}
