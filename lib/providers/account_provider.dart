// lib/providers/account_provider.dart
import 'dart:convert';

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

  List<Account> getAccountsByCategory(String categoryName) {
    return _accounts.where((a) => a.category == categoryName).toList();
  }

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
    
    // Also update all transactions for this account with the new category
    if (account.isDefined && account.category != null) {
      await DatabaseHelper.instance.updateTransactionsCategory(
        account.accountNumber,
        account.category!,
      );
    }
    
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

  Future<String> exportDefinedAccounts() async {
    final definedAccounts = _accounts.where((a) => a.isDefined).toList();

    if (definedAccounts.isEmpty) {
      return '';
    }

    // Create a list of maps with only the essential data
    final List<Map<String, dynamic>> exportData = definedAccounts.map((
      account,
    ) {
      return {
        'accountNumber': account.accountNumber,
        'name': account.name,
        'color': account.color.value,
        'category': account.category,
        'description': account.description,
      };
    }).toList();

    // Convert to JSON
    return jsonEncode(exportData);
  }

  Future<void> importDefinedAccounts(String jsonData) async {
    try {
      final List<dynamic> importedData = jsonDecode(jsonData);

      for (var data in importedData) {
        final accountNumber = data['accountNumber'];
        final existingAccount = getAccountByNumber(accountNumber);

        if (existingAccount != null) {
          // Update existing account with imported data
          final updatedAccount = Account(
            accountNumber: accountNumber,
            name: data['name'] ?? existingAccount.name,
            color: Color(data['color'] ?? existingAccount.color.value),
            category: data['category'],
            description: data['description'],
            isDefined: true,
          );
          await updateAccount(updatedAccount);
        } else {
          // Create new account if it doesn't exist
          final newAccount = Account(
            accountNumber: accountNumber,
            name: data['name'] ?? 'Импортлосон данс',
            color: Color(data['color'] ?? Colors.deepPurple.value),
            category: data['category'],
            description: data['description'],
            isDefined: true,
          );
          await addAccount(newAccount);
        }
      }

      await loadAccounts();
    } catch (e) {
      print('Error importing accounts: $e');
      rethrow;
    }
  }

  Account? getAccountByNumber(String accountNumber) {
    try {
      return _accounts.firstWhere((a) => a.accountNumber == accountNumber);
    } catch (e) {
      return null;
    }
  }
}
