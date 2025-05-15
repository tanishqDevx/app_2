import 'package:credit_tracker/models/payment_method.dart';

class Transaction {
  final int? id;
  final String date;
  final String customerName;
  final double sales;
  final double cash;
  final double payment;
  final String transactionType;
  final double outstanding;
  final int? relatedCreditId;
  final double totalReceived;
  List<PaymentMethod> paymentMethods = [];

  Transaction({
    this.id,
    required this.date,
    required this.customerName,
    required this.sales,
    required this.cash,
    required this.payment,
    required this.transactionType,
    required this.outstanding,
    this.relatedCreditId,
    this.totalReceived = 0,
    List<PaymentMethod>? paymentMethods,
  }) {
    if (paymentMethods != null) {
      this.paymentMethods = paymentMethods;
    }
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      customerName: map['customer_name'],
      sales: map['sales'] ?? 0,
      cash: map['cash'] ?? 0,
      payment: map['payment'] ?? 0,
      transactionType: map['transaction_type'],
      outstanding: map['outstanding'] ?? 0,
      relatedCreditId: map['related_credit_id'],
      totalReceived: map['total_received'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customer_name': customerName,
      'sales': sales,
      'cash': cash,
      'payment': payment,
      'transaction_type': transactionType,
      'outstanding': outstanding,
      'related_credit_id': relatedCreditId,
      'total_received': totalReceived,
    };
  }

  // Helper method to get digital payment total (excluding cash)
  double get digitalPaymentTotal {
    double total = 0;
    for (var method in paymentMethods) {
      total += method.amount;
    }
    return total;
  }

  // For backward compatibility
  double get hdfc {
    for (var method in paymentMethods) {
      if (method.method.toLowerCase().contains('hdfc') || 
          method.method.toLowerCase().contains('kotak') ||
          method.method.toLowerCase().contains('bank')) {
        return method.amount;
      }
    }
    return 0;
  }

  double get gpay {
    for (var method in paymentMethods) {
      if (method.method.toLowerCase().contains('gpay') || 
          method.method.toLowerCase().contains('google') ||
          method.method.toLowerCase().contains('pay')) {
        return method.amount;
      }
    }
    return 0;
  }
}
