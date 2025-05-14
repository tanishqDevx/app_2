class TransactionAccount {
  final int? id;
  final int transactionId;
  final int accountId;
  final double amount;

  TransactionAccount({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.amount,
  });

  factory TransactionAccount.fromMap(Map<String, dynamic> map) {
    return TransactionAccount(
      id: map['id'],
      transactionId: map['transaction_id'],
      accountId: map['account_id'],
      amount: map['amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'account_id': accountId,
      'amount': amount,
    };
  }

  static const String tableName = 'transaction_accounts';
  static const String createTableQuery = '''
    CREATE TABLE transaction_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      account_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
      FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
    )
  ''';
}
