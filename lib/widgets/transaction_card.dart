// lib/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

// Extension for string truncation
extension StringExtension on String {
  String truncate(int length) {
    return this.length > length ? '${substring(0, length)}...' : this;
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final bool showAccountInfo; // New parameter

  const TransactionCard({
    super.key,
    required this.transaction,
    this.showAccountInfo = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'mn_MN', symbol: '₮');
    final formatDate = DateFormat('yyyy/MM/dd HH:mm');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: transaction.expense > 0
              ? Colors.red.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          transaction.expense > 0
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          color: transaction.expense > 0 ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        (transaction.cleanedDescription?.isNotEmpty == true
                ? transaction.cleanedDescription!
                : transaction.description)
            .truncate(30),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            formatDate.format(transaction.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (transaction.counterpartyAccount != null &&
              transaction.counterpartyAccount!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Харьцсан: ${transaction.counterpartyAccount}',
                style: TextStyle(fontSize: 11, color: Colors.deepPurple[300]),
              ),
            ),
          if (showAccountInfo)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Данс: ${transaction.accountNumber}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (transaction.expense > 0)
            Text(
              '-${formatCurrency.format(transaction.expense)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (transaction.income > 0)
            Text(
              '+${formatCurrency.format(transaction.income)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            'Үлд: ${formatCurrency.format(transaction.endingBalance)}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}