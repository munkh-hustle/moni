// lib/models/transaction.dart
class BankTransaction {
  final int? id;
  final String bankName;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  final String accountNumber;
  final String? relatedAccount;
  final String? branch;
  final String? transactionValue;

  BankTransaction({
    this.id,
    required this.bankName,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.accountNumber,
    this.relatedAccount,
    this.branch,
    this.transactionValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'date': date.toIso8601String(),
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'accountNumber': accountNumber,
      'relatedAccount': relatedAccount,
      'branch': branch,
      'transactionValue': transactionValue,
    };
  }

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      id: map['id'],
      bankName: map['bankName'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      debit: map['debit'],
      credit: map['credit'],
      balance: map['balance'],
      accountNumber: map['accountNumber'],
      relatedAccount: map['relatedAccount'],
      branch: map['branch'],
      transactionValue: map['transactionValue'],
    );
  }
}