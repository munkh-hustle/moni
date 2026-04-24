// lib/screens/account_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/transaction_card.dart';

class AccountDetailsScreen extends StatelessWidget {
  final Account account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  Color _getAccountColor(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    
    // If account has a category, find the category and return its color
    if (account.category != null) {
      final category = accountProvider.categories
          .firstWhere((c) => c.name == account.category, orElse: () => Category(name: '', color: Colors.grey));
      return category.color;
    }
    
    // If no category, return grey color for unassigned accounts
    return Colors.grey[800]!;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'mn_MN', symbol: '₮');
    final accountColor = _getAccountColor(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with account info
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: accountColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        account.accountNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      if (account.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            account.category!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accountColor.withOpacity(0.8),
                      accountColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 120,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Account Summary Card (BALANCE REMOVED, only income/expense)
          SliverToBoxAdapter(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                // Get transactions for this account
                final accountTransactions = transactionProvider.transactions
                    .where((t) => t.accountNumber == account.accountNumber)
                    .toList();
                
                double totalIncome = 0;
                double totalExpense = 0;
                
                if (accountTransactions.isNotEmpty) {
                  totalIncome = accountTransactions.fold(0, (sum, t) => sum + t.income);
                  totalExpense = accountTransactions.fold(0, (sum, t) => sum + t.expense);
                }
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accountColor.withOpacity(0.8),
                          accountColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accountColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Income
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Орлого',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatCurrency.format(totalIncome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Vertical divider
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        
                        // Expense
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Зарлага',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatCurrency.format(totalExpense),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Transactions Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ГҮЙЛГЭЭНҮҮД',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          // Transactions List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final accountTransactions = transactionProvider.transactions
                    .where((t) => t.accountNumber == account.accountNumber)
                    .toList();
                
                if (accountTransactions.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Гүйлгээ байхгүй',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = accountTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionCard(
                          transaction: transaction,
                          showAccountInfo: false,
                          accountCategory: account.category,
                        ),
                      );
                    },
                    childCount: accountTransactions.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}