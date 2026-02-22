// lib/models/transaction.dart
class Transaction {
  int? id;
  DateTime date;
  double beginningBalance;
  double expense;
  double income;
  double endingBalance;
  String description;
  String? counterpartyAccount;
  String accountNumber;
  String bankType;
  String? category;
  bool isDefined;

  Transaction({
    this.id,
    required this.date,
    required this.beginningBalance,
    required this.expense,
    required this.income,
    required this.endingBalance,
    required this.description,
    this.counterpartyAccount,
    required this.accountNumber,
    required this.bankType,
    this.category,
    this.isDefined = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'beginningBalance': beginningBalance,
      'expense': expense,
      'income': income,
      'endingBalance': endingBalance,
      'description': description,
      'counterpartyAccount': counterpartyAccount,
      'accountNumber': accountNumber,
      'bankType': bankType,
      'category': category,
      'isDefined': isDefined ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: DateTime.parse(map['date']),
      beginningBalance: map['beginningBalance'],
      expense: map['expense'],
      income: map['income'],
      endingBalance: map['endingBalance'],
      description: map['description'],
      counterpartyAccount: map['counterpartyAccount'],
      accountNumber: map['accountNumber'],
      bankType: map['bankType'],
      category: map['category'],
      isDefined: map['isDefined'] == 1,
    );
  }
}