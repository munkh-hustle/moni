// lib\providers\account_provider.dart
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_database.dart';

class AccountProvider extends ChangeNotifier {
  List<AccountCategory> _accounts = [];
  List<AccountCategory> _filteredAccounts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<AccountCategory> get accounts => _filteredAccounts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();
    
    _accounts = await AccountDatabaseService.getAccounts();
    _filteredAccounts = _accounts;
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAccount(AccountCategory account) async {
    await AccountDatabaseService.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(AccountCategory account) async {
    await AccountDatabaseService.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String accountNumber) async {
    await AccountDatabaseService.deleteAccount(accountNumber);
    await loadAccounts();
  }

  Future<void> toggleAccount(String accountNumber, bool isActive) async {
    await AccountDatabaseService.toggleAccount(accountNumber, isActive);
    await loadAccounts();
  }

  void searchAccounts(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredAccounts = _accounts;
    } else {
      _filteredAccounts = _accounts.where((account) {
        return account.accountNumber.toLowerCase().contains(query.toLowerCase()) ||
               account.name.toLowerCase().contains(query.toLowerCase()) ||
               account.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredAccounts = _accounts;
    notifyListeners();
  }

  AccountCategory? getCategoryForAccount(String accountNumber) {
    // First check exact match
    for (var account in _accounts) {
      if (accountNumber.contains(account.accountNumber)) {
        return account;
      }
    }
    
    // Return default category if not found
    return AccountCategory(
      accountNumber: accountNumber,
      category: 'other',
      name: 'Unknown Account',
      color: Colors.grey,
    );
  }

  List<AccountCategory> getAllCategories() {
    return _accounts;
  }
}