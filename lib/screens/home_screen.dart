// lib/screens/home_screen.dart - Updated version with only account cards

import 'package:flutter/material.dart';
import 'package:moni/models/account.dart';
import 'package:moni/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/account_category_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'mn_MN', symbol: '₮');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Санхүүгийн хяналт'),
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

          return CustomScrollView(
            slivers: [
              // Overall Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BalanceCard(
                    balance: transactionProvider.getCurrentBalance(),
                    income: transactionProvider.getTotalIncome(),
                    expense: transactionProvider.getTotalExpenses(),
                  ),
                ),
              ),
              
              // Account Category Cards Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ДАНСНУУД',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final account = accountProvider.accounts[index];
                      final totals = accountTotals[account.accountNumber] ?? {
                        'income': 0,
                        'expense': 0,
                        'balance': 0,
                      };
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AccountCategoryCard(
                          account: account,
                          balance: totals['balance'] ?? 0,
                          income: totals['income'] ?? 0,
                          expense: totals['expense'] ?? 0,
                          formatCurrency: formatCurrency,
                        ),
                      );
                    },
                    childCount: accountProvider.accounts.length,
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