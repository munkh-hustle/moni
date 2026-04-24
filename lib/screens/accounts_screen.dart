// lib/screens/accounts_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/account_provider.dart';
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
                            onPressed: () =>
                                _showEditCategoryDialog(context, category),
                          ),
                          if (index >
                              5) // Don't allow deleting default categories
                            IconButton(
                              icon: const Icon(Icons.delete_rounded),
                              onPressed: () =>
                                  _showDeleteCategoryDialog(context, category),
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
