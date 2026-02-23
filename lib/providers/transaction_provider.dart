// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  Map<String, List<Transaction>> _groupedByCounterparty = {};
  Map<String, List<Transaction>> get groupedByCounterparty =>
      _groupedByCounterparty;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _transactions = await DatabaseHelper.instance.getAllTransactions();
    _groupTransactionsByCounterparty();
    notifyListeners();
  }

  void _groupTransactionsByCounterparty() {
    _groupedByCounterparty = {};

    for (var transaction in _transactions) {
      // Clean the description first
      final cleanedDescription = cleanDescription(transaction.description);

      // Create a copy of the transaction with cleaned description for grouping
      // But don't modify the original transaction
      String groupKey;

      if (transaction.counterpartyAccount?.isNotEmpty == true) {
        // Use counterparty account if available
        groupKey = transaction.counterpartyAccount!;
      } else {
        // Use cleaned description for grouping
        groupKey = cleanedDescription.isNotEmpty
            ? cleanedDescription
            : transaction.description;
      }

      // Add context prefix for description-based groups
      if (transaction.counterpartyAccount?.isEmpty != false) {
        groupKey = '[Гүйлгээ] $groupKey';
      }

      if (!_groupedByCounterparty.containsKey(groupKey)) {
        _groupedByCounterparty[groupKey] = [];
      }
      _groupedByCounterparty[groupKey]!.add(transaction);
    }

    // Sort transactions within each group by date (newest first)
    _groupedByCounterparty.forEach((key, transactions) {
      transactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // Helper method to check if a group is a counterparty account or description
  bool isCounterpartyGroup(String groupKey) {
    return !groupKey.startsWith('[Гүйлгээ]');
  }

  // Get the clean group name without prefix
  String getCleanGroupName(String groupKey) {
    if (groupKey.startsWith('[Гүйлгээ]')) {
      return groupKey.substring(9); // Remove '[Гүйлгээ] ' prefix
    }
    return groupKey;
  }

  String cleanDescription(String description) {
    if (description.isEmpty) return description;

    // Pattern 1: TRF=... format
    // Matches: TRF=002150052746-949628XXXXXX5711-UGUUJ CHIKHER BO
    final trfPattern = RegExp(r'^TRF=[A-Z0-9]+-[A-Z0-9]+-');
    if (trfPattern.hasMatch(description)) {
      return description.replaceFirst(trfPattern, '');
    }

    // Pattern 2: qpay ... format
    // Matches: qpay 524441280812199 Бэлэг-Өрнөх Дашгаадан 8000 TR
    final qpayPattern = RegExp(r'^qpay\s+\d+\s+');
    if (qpayPattern.hasMatch(description)) {
      return description.replaceFirst(qpayPattern, '');
    }

    // Pattern 3: QPAY ... format (uppercase)
    final qpayUppercasePattern = RegExp(r'^QPAY\s+[A-Z0-9]+\s+');
    if (qpayUppercasePattern.hasMatch(description)) {
      return description.replaceFirst(qpayUppercasePattern, '');
    }

    // Pattern 4: Numbers at the beginning followed by space (like "57508 ,90696009")
    final numberPattern = RegExp(r'^\d+\s*,?\s*');
    if (numberPattern.hasMatch(description)) {
      return description.replaceFirst(numberPattern, '');
    }

    return description;
  }

  String getCleanDescription(String originalDescription) {
  return cleanDescription(originalDescription);
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

  // Get total for a specific group
  Map<String, double> getGroupTotals(String groupKey) {
    double totalExpense = 0;
    double totalIncome = 0;

    final groupTransactions = _groupedByCounterparty[groupKey] ?? [];
    for (var t in groupTransactions) {
      totalExpense += t.expense;
      totalIncome += t.income;
    }

    return {'expense': totalExpense, 'income': totalIncome};
  }
}
