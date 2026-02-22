// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:moni/models/account.dart';
import 'package:moni/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'mn_MN', symbol: '₮');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гүйлгээнүүд'),
        actions: [
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
          if (transactionProvider.groupedByAccount.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Гүйлгээ байхгүй байна',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactionProvider.groupedByAccount.length,
            itemBuilder: (context, index) {
              final accountNumber = transactionProvider.groupedByAccount.keys
                  .elementAt(index);
              final accountTransactions = 
                  transactionProvider.groupedByAccount[accountNumber]!;
              final account = accountProvider.getAccountByNumber(accountNumber);

              // Calculate account summary
              double totalExpense = 0;
              double totalIncome = 0;
              for (var t in accountTransactions) {
                totalExpense += t.expense;
                totalIncome += t.income;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            account?.color ?? Colors.deepPurple,
                            (account?.color ?? Colors.deepPurple).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account?.name ?? 'Тодорхойгүй данс',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  accountNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Зарлага: ${formatCurrency.format(totalExpense)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Орлого: ${formatCurrency.format(totalIncome)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Transactions List
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(15),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: accountTransactions.length > 3 
                            ? 3 : accountTransactions.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, transactionIndex) {
                          final transaction = accountTransactions[transactionIndex];
                          return TransactionCard(transaction: transaction);
                        },
                      ),
                    ),
                    if (accountTransactions.length > 3)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(15),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            _showAllTransactions(
                              context, 
                              accountNumber, 
                              accountTransactions,
                              account,
                            );
                          },
                          child: Text(
                            'Бүгдийг харах (${accountTransactions.length})',
                            style: const TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAllTransactions(
    BuildContext context,
    String accountNumber,
    List<Transaction> transactions,
    Account? account,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: account?.color ?? Colors.deepPurple,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account?.name ?? 'Тодорхойгүй данс',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          accountNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionCard(transaction: transaction),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}