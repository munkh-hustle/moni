// lib/providers/account_provider.dart
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  List<Account> _undefinedAccounts = [];
  List<Account> get undefinedAccounts => _undefinedAccounts;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  AccountProvider() {
    loadAccounts();
    loadCategories();
  }

  Future<void> loadAccounts() async {
    _accounts = await DatabaseHelper.instance.getAllAccounts();
    _undefinedAccounts = _accounts.where((a) => !a.isDefined).toList();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await DatabaseHelper.instance.getAllCategories();
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    await DatabaseHelper.instance.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    await DatabaseHelper.instance.updateAccount(account);
    await loadAccounts();
  }

  Future<void> addCategory(Category category) async {
    await DatabaseHelper.instance.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await DatabaseHelper.instance.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await loadCategories();
  }

  Account? getAccountByNumber(String accountNumber) {
    try {
      return _accounts.firstWhere((a) => a.accountNumber == accountNumber);
    } catch (e) {
      return null;
    }
  }
}