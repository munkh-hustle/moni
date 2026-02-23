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
import '../widgets/account_category_card.dart'; // New import

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
          if (transactionProvider.groupedByCounterparty.isEmpty) {
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
              
              // Account Category Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ДАНСНУУД',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
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
              
              // Transactions by Counterparty Section
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ГҮЙЛГЭЭНҮҮД',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
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
                      final groupKey = transactionProvider.groupedByCounterparty.keys
                          .elementAt(index);
                      final groupTransactions = 
                          transactionProvider.groupedByCounterparty[groupKey]!;
                      
                      final isCounterparty = transactionProvider.isCounterpartyGroup(groupKey);
                      final cleanName = transactionProvider.getCleanGroupName(groupKey);
                      
                      final firstTransaction = groupTransactions.first;
                      final account = accountProvider.getAccountByNumber(firstTransaction.accountNumber);

                      final totals = transactionProvider.getGroupTotals(groupKey);
                      final totalExpense = totals['expense']!;
                      final totalIncome = totals['income']!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Group Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCounterparty
                                      ? [Colors.deepPurple, Colors.purple]
                                      : [Colors.blueGrey, Colors.grey],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCounterparty
                                          ? Icons.account_balance_rounded
                                          : Icons.receipt_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cleanName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isCounterparty
                                              ? 'Харьцсан данс'
                                              : 'Гүйлгээний утга',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (totalExpense > 0)
                                        Text(
                                          'Зарлага: ${formatCurrency.format(totalExpense)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (totalIncome > 0)
                                        Text(
                                          'Орлого: ${formatCurrency.format(totalIncome)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        '${groupTransactions.length} гүйлгээ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.8),
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
                                itemCount: groupTransactions.length > 3 
                                    ? 3 : groupTransactions.length,
                                separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                itemBuilder: (context, transactionIndex) {
                                  final transaction = groupTransactions[transactionIndex];
                                  final account = accountProvider.getAccountByNumber(transaction.accountNumber);
                                  
                                  return TransactionCard(
                                    transaction: transaction,
                                    showAccountInfo: true,
                                    accountCategory: account?.category,
                                  );
                                },
                              ),
                            ),
                            if (groupTransactions.length > 3)
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
                                      groupKey,
                                      cleanName,
                                      groupTransactions,
                                      isCounterparty,
                                      account,
                                    );
                                  },
                                  child: Text(
                                    'Бүгдийг харах (${groupTransactions.length})',
                                    style: const TextStyle(color: Colors.deepPurple),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: transactionProvider.groupedByCounterparty.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAllTransactions(
    BuildContext context,
    String groupKey,
    String cleanName,
    List<Transaction> transactions,
    bool isCounterparty,
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
                gradient: LinearGradient(
                  colors: isCounterparty
                      ? [Colors.deepPurple, Colors.purple]
                      : [Colors.blueGrey, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                          cleanName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isCounterparty
                              ? 'Харьцсан данс'
                              : 'Гүйлгээний утга',
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
                  final account = Provider.of<AccountProvider>(context, listen: false)
                      .getAccountByNumber(transaction.accountNumber);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionCard(
                      transaction: transaction,
                      showAccountInfo: true,
                      accountCategory: account?.category,
                    ),
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