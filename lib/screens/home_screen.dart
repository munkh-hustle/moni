import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart'; // Add this import
import '../models/account.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data
      context.read<TransactionProvider>().loadTransactions();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moni - Financial Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.pushNamed(context, '/accounts');
            },
            tooltip: 'Manage Accounts',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data'),
                  content: const Text('Are you sure you want to delete all transactions?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<TransactionProvider>().clearAllTransactions();
                        Navigator.pop(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, AccountProvider>(
        builder: (context, transactionProvider, accountProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = transactionProvider.transactions;
          final spendingByAccount = transactionProvider.getSpendingByAccount();

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/import');
                    },
                    child: const Text('Import Bank Statements'),
                  ),
                ],
              ),
            );
          }

          // Calculate totals
          double totalDebit = 0;
          double totalCredit = 0;
          for (var transaction in transactions) {
            totalDebit += transaction.debit;
            totalCredit += transaction.credit;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Debit',
                        value: '₮${totalDebit.toStringAsFixed(0)}',
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Credit',
                        value: '₮${totalCredit.toStringAsFixed(0)}',
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Transactions',
                        value: transactions.length.toString(),
                        color: Colors.blue,
                        icon: Icons.list,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Accounts',
                        value: spendingByAccount.keys.length.toString(),
                        color: Colors.purple,
                        icon: Icons.account_balance,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Account Categories Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/accounts'),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                Expanded(
                  child: _buildAccountCategoriesList(accountProvider, spendingByAccount),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/import');
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Import'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/analysis');
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCategoriesList(
    AccountProvider accountProvider,
    Map<String, double> spendingByAccount,
  ) {
    final accounts = accountProvider.getAllCategories();
    
    if (accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text('No accounts configured'),
            SizedBox(height: 5),
            Text('Add accounts to track spending'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final accountSpending = spendingByAccount[account.accountNumber] ?? 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: account.color.withOpacity(0.2),
              child: Icon(
                _getIconForCategory(account.category),
                color: account.color,
              ),
            ),
            title: Text(account.name),
            subtitle: Text('Account: ${account.accountNumber}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₮${accountSpending.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accountSpending > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                if (accountSpending > 0)
                  Text(
                    '${_getTransactionCount(account.accountNumber)} transactions',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () {
              _showAccountDetails(context, account.accountNumber);
            },
          ),
        );
      },
    );
  }

  int _getTransactionCount(String accountNumber) {
    final transactionProvider = context.read<TransactionProvider>();
    return transactionProvider.getTransactionsForAccount(accountNumber).length;
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'family':
        return Icons.family_restroom;
      case 'education':
        return Icons.school;
      case 'personal':
        return Icons.person;
      case 'business':
        return Icons.business;
      case 'investment':
        return Icons.trending_up;
      case 'shopping':
        return Icons.shopping_cart;
      case 'utilities':
        return Icons.bolt;
      case 'subscriptions':
        return Icons.subscriptions;
      default:
        return Icons.category;
    }
  }

  void _showAccountDetails(BuildContext context, String accountNumber) {
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final transactions = transactionProvider.getTransactionsForAccount(accountNumber);
    final category = accountProvider.getCategoryForAccount(accountNumber);
    
    double totalSpent = 0;
    for (var transaction in transactions) {
      totalSpent += transaction.debit;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: category!.color.withOpacity(0.2),
                    child: Icon(
                      _getIconForCategory(category.category),
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text('Account: $accountNumber'),
                        Text(
                          category.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: category.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Total Spent'),
                      Text(
                        '₮${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text('${transactions.length} transactions'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 10),
              
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('No transactions for this account'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transaction.debit > 0 
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                child: Icon(
                                  transaction.debit > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: transaction.debit > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(
                                transaction.description.length > 50
                                    ? '${transaction.description.substring(0, 50)}...'
                                    : transaction.description,
                              ),
                              subtitle: Text(
                                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} • ${transaction.bankName}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    transaction.debit > 0 
                                        ? '-₮${transaction.debit.toStringAsFixed(0)}'
                                        : '+₮${transaction.credit.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: transaction.debit > 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Balance: ₮${transaction.balance.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}