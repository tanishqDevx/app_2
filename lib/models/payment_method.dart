class PaymentMethod {
  final int? id;
  final int transactionId;
  final String method;
  final double amount;

  PaymentMethod({
    this.id,
    required this.transactionId,
    required this.method,
    required this.amount,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      transactionId: map['transaction_id'],
      method: map['method'],
      amount: map['amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'method': method,
      'amount': amount,
    };
  }
}
