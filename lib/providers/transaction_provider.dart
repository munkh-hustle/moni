// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  Map<String, List<Transaction>> _groupedByAccount = {};
  Map<String, List<Transaction>> get groupedByAccount => _groupedByAccount;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _transactions = await DatabaseHelper.instance.getAllTransactions();
    _groupTransactionsByAccount();
    notifyListeners();
  }

  void _groupTransactionsByAccount() {
    _groupedByAccount = {};
    for (var transaction in _transactions) {
      if (!_groupedByAccount.containsKey(transaction.accountNumber)) {
        _groupedByAccount[transaction.accountNumber] = [];
      }
      _groupedByAccount[transaction.accountNumber]!.add(transaction);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  double getTotalExpenses() {
    return _transactions.fold(0, (sum, item) => sum + item.expense);
  }

  double getTotalIncome() {
    return _transactions.fold(0, (sum, item) => sum + item.income);
  }

  double getCurrentBalance() {
    if (_transactions.isEmpty) return 0;
    return _transactions.first.endingBalance;
  }
}