// lib/screens/accounts_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/account.dart';
import '../models/category.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категори'),
      ),
      body: const CategoriesTab(),
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accountProvider, transactionProvider, child) {
        final categoryTotals = transactionProvider.getCategoryTotals();
        final assignedAccounts = accountProvider.accounts.where((a) => a.isDefined).toList();
        
        // Group accounts by category
        Map<String, List<Account>> accountsByCategory = {};
        for (var account in assignedAccounts) {
          if (account.category != null && account.category!.isNotEmpty) {
            if (!accountsByCategory.containsKey(account.category)) {
              accountsByCategory[account.category!] = [];
            }
            accountsByCategory[account.category!]!.add(account);
          }
        }
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Шинэ категори'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            Expanded(
              child: accountsByCategory.isEmpty
                  ? const Center(
                      child: Text(
                        'Одоогоор категоритай данс байхгүй',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: accountsByCategory.length,
                      itemBuilder: (context, categoryIndex) {
                        final categoryName = accountsByCategory.keys.elementAt(categoryIndex);
                        final accountsInCategory = accountsByCategory[categoryName]!;
                        
                        // Find the category to get its color
                        final category = accountProvider.categories.firstWhere(
                          (c) => c.name == categoryName,
                          orElse: () => Category(name: categoryName, color: Colors.deepPurple),
                        );
                        
                        final totalSpent = categoryTotals[categoryName] ?? 0;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: category.color,
                                    radius: 18,
                                    child: Text(
                                      categoryName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '${accountsInCategory.length} данс | Зарлага: ${NumberFormat.currency(locale: 'mn_MN', symbol: '₮', decimalDigits: 0).format(totalSpent)}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Accounts in this category
                            ...accountsInCategory.map((account) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: account.color.withOpacity(0.1),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: account.color,
                                    child: Text(
                                      account.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(account.name),
                                  subtitle: Text(
                                    account.accountNumber,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  trailing: Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: account.color,
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    Color selectedColor =
        Colors.primaries[Random().nextInt(Colors.primaries.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Категори нэмэх'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Категорийн нэр'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Төсөв (₮)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Өнгө сонгох'),
              const SizedBox(height: 8),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => selectedColor = color,
                showLabel: false,
                pickerAreaHeightPercent: 0.8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final category = Category(
                  name: nameController.text,
                  color: selectedColor,
                  budget: double.tryParse(budgetController.text) ?? 0,
                );
                await Provider.of<AccountProvider>(
                  context,
                  listen: false,
                ).addCategory(category);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final budgetController = TextEditingController(
      text: category.budget.toString(),
    );
    Color selectedColor = category.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Категори засах'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Категорийн нэр'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Төсөв (₮)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Өнгө сонгох'),
              const SizedBox(height: 8),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => selectedColor = color,
                showLabel: false,
                pickerAreaHeightPercent: 0.8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedCategory = Category(
                id: category.id,
                name: nameController.text,
                color: selectedColor,
                budget:
                    double.tryParse(budgetController.text) ?? category.budget,
              );
              await Provider.of<AccountProvider>(
                context,
                listen: false,
              ).updateCategory(updatedCategory);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Категори устгах'),
        content: Text('${category.name} категорийг устгах уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<AccountProvider>(
                context,
                listen: false,
              ).deleteCategory(category.id!);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
  }
}
