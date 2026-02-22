// lib/screens/accounts_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import '../models/category.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Данс & Категори'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Тодорхойгүй данс'),
            Tab(text: 'Категори'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UndefinedAccountsTab(),
          CategoriesTab(),
        ],
      ),
    );
  }
}

class UndefinedAccountsTab extends StatelessWidget {
  const UndefinedAccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.undefinedAccounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Бүх данс тодорхойлогдсон',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.undefinedAccounts.length,
          itemBuilder: (context, index) {
            final account = provider.undefinedAccounts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: account.color,
                  child: Text(
                    account.accountNumber.substring(0, 2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(account.name),
                subtitle: Text(account.accountNumber),
                trailing: ElevatedButton(
                  onPressed: () => _showDefineAccountDialog(context, account),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Тодорхойлох'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDefineAccountDialog(BuildContext context, Account account) {
    final nameController = TextEditingController(text: account.name);
    Color selectedColor = account.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Данс тодорхойлох'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Дансны нэр',
                  hintText: 'Жишээ: Цалингийн данс',
                ),
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
              final updatedAccount = Account(
                accountNumber: account.accountNumber,
                name: nameController.text,
                color: selectedColor,
                isDefined: true,
              );
              await Provider.of<AccountProvider>(context, listen: false)
                  .updateAccount(updatedAccount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color,
                        child: Text(
                          category.name.substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(category.name),
                      subtitle: Text(
                        'Төсөв: ${NumberFormat.currency(locale: 'mn_MN', symbol: '₮').format(category.budget)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _showEditCategoryDialog(
                              context,
                              category,
                            ),
                          ),
                          if (index > 5) // Don't allow deleting default categories
                            IconButton(
                              icon: const Icon(Icons.delete_rounded),
                              onPressed: () => _showDeleteCategoryDialog(
                                context,
                                category,
                              ),
                            ),
                        ],
                      ),
                    ),
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
    Color selectedColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];

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
                decoration: const InputDecoration(
                  labelText: 'Категорийн нэр',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Төсөв (₮)',
                ),
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
                await Provider.of<AccountProvider>(context, listen: false)
                    .addCategory(category);
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
                decoration: const InputDecoration(
                  labelText: 'Категорийн нэр',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Төсөв (₮)',
                ),
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
                budget: double.tryParse(budgetController.text) ?? category.budget,
              );
              await Provider.of<AccountProvider>(context, listen: false)
                  .updateCategory(updatedCategory);
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
              await Provider.of<AccountProvider>(context, listen: false)
                  .deleteCategory(category.id!);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
  }
}