// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database.dart';

class TransactionProvider extends ChangeNotifier {
  List<BankTransaction> _transactions = [];
  bool _isLoading = false;

  List<BankTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    
    _transactions = await DatabaseService.getTransactions();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransactions(List<BankTransaction> newTransactions) async {
    await DatabaseService.insertTransactions(newTransactions);
    await loadTransactions();
  }

  Future<void> clearAllTransactions() async {
    await DatabaseService.clearAllTransactions();
    _transactions = [];
    notifyListeners();
  }

  Map<String, double> getSpendingByAccount() {
    Map<String, double> spending = {};
    
    for (var transaction in _transactions) {
      if (transaction.debit > 0) {
        String account = transaction.relatedAccount ?? 'Unknown';
        spending[account] = (spending[account] ?? 0) + transaction.debit;
      }
    }
    
    return spending;
  }

  List<BankTransaction> getTransactionsForAccount(String accountNumber) {
    return _transactions.where((transaction) {
      return transaction.relatedAccount == accountNumber ||
             transaction.accountNumber == accountNumber ||
             transaction.description.contains(accountNumber);
    }).toList();
  }
}