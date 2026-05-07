// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:moni/models/account.dart';
import 'package:moni/models/transaction.dart';
import 'package:moni/models/category.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/account_category_card.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sortBy = 'name'; // 'name', 'expense', 'income', 'category'

  void _showDefineAccountDialog(BuildContext context, Account account) {
    final nameController = TextEditingController(text: account.name);
    Color selectedColor = account.color;

    // Get categories from provider
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    // Check if the current category still exists
    String? selectedCategory = account.category;
    if (selectedCategory != null) {
      final categoryExists = accountProvider.categories.any(
        (c) => c.name == selectedCategory,
      );
      if (!categoryExists) {
        selectedCategory = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Данс тодорхойлох'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Дансны нэр',
                    hintText: 'Жишээ: Цалингийн данс',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Категори сонгох',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      hint: const Text('Категори сонгох'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Категоригүй'),
                        ),
                        ...accountProvider.categories.map((category) {
                          return DropdownMenuItem(
                            value: category.name,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                  ),
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
                  color: account.color, // Keep original color, not editable
                  isDefined: true,
                  category: selectedCategory,
                );
                await Provider.of<AccountProvider>(
                  context,
                  listen: false,
                ).updateAccount(updatedAccount);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Хадгалах'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'mn_MN', symbol: '₮');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Санхүүгийн хяналт'),
        actions: [
          // Sort dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Эрэмбэлэх',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.label, size: 20),
                    SizedBox(width: 8),
                    Text('Нэрээр'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expense',
                child: Row(
                  children: [
                    Icon(Icons.trending_down, size: 20),
                    SizedBox(width: 8),
                    Text('Зарлагаар'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'income',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('Орлогоор'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('Категориар'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false)
                  .loadTransactions();
              Provider.of<AccountProvider>(context, listen: false)
                  .loadAccounts();
            },
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, AccountProvider>(
        builder: (context, transactionProvider, accountProvider, child) {
          if (accountProvider.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Данс байхгүй байна',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CSV файл импортлоно уу',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate totals for each account
          final Map<String, Map<String, double>> accountTotals = {};
          
          for (var transaction in transactionProvider.transactions) {
            if (!accountTotals.containsKey(transaction.accountNumber)) {
              accountTotals[transaction.accountNumber] = {
                'income': 0,
                'expense': 0,
                'balance': transaction.endingBalance,
              };
            }
            
            accountTotals[transaction.accountNumber]!['income'] = 
                (accountTotals[transaction.accountNumber]!['income'] ?? 0) + transaction.income;
            accountTotals[transaction.accountNumber]!['expense'] = 
                (accountTotals[transaction.accountNumber]!['expense'] ?? 0) + transaction.expense;
          }

          // Create a list of accounts with their totals for sorting
          final List<Map<String, dynamic>> accountsWithTotals = [];
          for (var account in accountProvider.accounts) {
            final totals = accountTotals[account.accountNumber] ?? {
              'income': 0,
              'expense': 0,
              'balance': 0,
            };
            accountsWithTotals.add({
              'account': account,
              'income': totals['income'] ?? 0,
              'expense': totals['expense'] ?? 0,
              'balance': totals['balance'] ?? 0,
            });
          }

          // Sort accounts based on selected sort option
          if (_sortBy == 'expense') {
            accountsWithTotals.sort((a, b) => (b['expense'] as double).compareTo(a['expense'] as double));
          } else if (_sortBy == 'income') {
            accountsWithTotals.sort((a, b) => (b['income'] as double).compareTo(a['income'] as double));
          } else if (_sortBy == 'category') {
            accountsWithTotals.sort((a, b) {
              final catA = ((a['account'] as Account).category ?? '').toLowerCase();
              final catB = ((b['account'] as Account).category ?? '').toLowerCase();
              return catA.compareTo(catB);
            });
          } else {
            // Default: sort by name
            accountsWithTotals.sort((a, b) => 
              ((a['account'] as Account).name).compareTo((b['account'] as Account).name));
          }

          return CustomScrollView(
            slivers: [
              // Account Category Cards Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    'ДАНСНУУД',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final accountData = accountsWithTotals[index];
                      final account = accountData['account'] as Account;
                      final income = accountData['income'] as double;
                      final expense = accountData['expense'] as double;
                      final balance = accountData['balance'] as double;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AccountCategoryCard(
                          account: account,
                          balance: balance,
                          income: income,
                          expense: expense,
                          formatCurrency: formatCurrency,
                          categories: accountProvider.categories,
                          onDefineAccount: () {
                            _showDefineAccountDialog(context, account);
                          },
                        ),
                      );
                    },
                    childCount: accountsWithTotals.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}