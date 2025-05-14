class Account {
  final int? id;
  final String name;
  final String category;
  final bool isActive;

  Account({
    this.id,
    required this.name,
    required this.category,
    this.isActive = true,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_active': isActive ? 1 : 0,
    };
  }

  static const String tableName = 'accounts';
  static const String createTableQuery = '''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      is_active INTEGER DEFAULT 1
    )
  ''';
}
