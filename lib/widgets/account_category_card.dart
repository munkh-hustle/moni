// lib/widgets/account_category_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../screens/account_details_screen.dart';

class AccountCategoryCard extends StatelessWidget {
  final Account account;
  final double balance;
  final double income;
  final double expense;
  final NumberFormat formatCurrency;
  final List<Category> categories;
  final VoidCallback? onDefineAccount;

  const AccountCategoryCard({
    super.key,
    required this.account,
    required this.balance,
    required this.income,
    required this.expense,
    required this.formatCurrency,
    required this.categories,
    this.onDefineAccount,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if account is assigned (has a valid category)
    final bool isAssigned = account.isDefined && account.category != null;
    
    // Get the category color if assigned, otherwise use grey
    Color cardColor;
    if (isAssigned) {
      final category = categories.firstWhere(
        (c) => c.name == account.category,
        orElse: () => Category(name: '', color: Colors.grey),
      );
      cardColor = category.color;
    } else {
      cardColor = Colors.grey[800]!;
    }

    return Dismissible(
      key: Key(account.accountNumber),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Тодорхойлох',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (onDefineAccount != null) {
          onDefineAccount!();
        }
        return false; // Don't actually dismiss, just show dialog
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.9), cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountDetailsScreen(account: account),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with account icon, name, and chevron
                  Row(
                    children: [
                      // Account icon with larger size
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            account.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Account name and number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account.accountNumber,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Navigation chevron
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // PROMINENT CATEGORY DISPLAY
                  if (account.category != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              account.category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Show "Unassigned" label for unassigned accounts
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_outline_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Тодорхойлогдоогүй',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Income and Expense row (BALANCE REMOVED)
                  Row(
                    children: [
                      // Income
                      Expanded(
                        child: _buildStatColumn(
                          'Орлого',
                          formatCurrency.format(income),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Expense
                      Expanded(
                        child: _buildStatColumn(
                          'Зарлага',
                          formatCurrency.format(expense),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}