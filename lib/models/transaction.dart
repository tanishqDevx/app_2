class Transaction {
  final int? id;
  final String date;
  final String customerName;
  final double sales;
  final double cash;
  final double hdfc;
  final double gpay;
  final double payment;
  final String transactionType;
  final double outstanding;
  final int? relatedCreditId;

  Transaction({
    this.id,
    required this.date,
    required this.customerName,
    required this.sales,
    required this.cash,
    required this.hdfc,
    required this.gpay,
    required this.payment,
    required this.transactionType,
    required this.outstanding,
    this.relatedCreditId,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      customerName: map['customer_name'],
      sales: map['sales'],
      cash: map['cash'],
      hdfc: map['hdfc'],
      gpay: map['gpay'],
      payment: map['payment'],
      transactionType: map['transaction_type'],
      outstanding: map['outstanding'],
      relatedCreditId: map['related_credit_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customer_name': customerName,
      'sales': sales,
      'cash': cash,
      'hdfc': hdfc,
      'gpay': gpay,
      'payment': payment,
      'transaction_type': transactionType,
      'outstanding': outstanding,
      'related_credit_id': relatedCreditId,
    };
  }

  double get totalReceived => cash + hdfc + gpay;
}
