// lib/screens/settings_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDuplicateTransaction(
    Transaction newTransaction,
    List<Transaction> existingTransactions,
  ) {
    return existingTransactions.any(
      (existing) =>
          existing.date.isAtSameMomentAs(newTransaction.date) &&
          existing.expense == newTransaction.expense &&
          existing.income == newTransaction.income &&
          existing.description == newTransaction.description &&
          existing.accountNumber == newTransaction.accountNumber,
    );
  }

  int _importedCount = 0;
  int _skippedCount = 0;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo Data Load Button
          Card(
            color: Colors.deepPurple.withOpacity(0.1),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'DEMO ӨГӨГДӨЛ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                  title: const Text('Demo өгөгдөл ачаалах'),
                  subtitle: const Text('JSON болон CSV файлыг автоматаар импортлох'),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => _loadDemoData(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Section
          const Text(
            'МЭДЭЭЛЭЛ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildInfoTile(
                  Icons.storage_rounded,
                  'Өгөгдлийн сан',
                  '${_getDatabaseSize()} MB',
                ),
                const Divider(height: 1, indent: 16),
                _buildInfoTile(
                  Icons.receipt_long_rounded,
                  'Нийт гүйлгээ',
                  Provider.of<TransactionProvider>(
                    context,
                  ).transactions.length.toString(),
                ),
                const Divider(height: 1, indent: 16),
                _buildInfoTile(
                  Icons.account_balance_rounded,
                  'Нийт данс',
                  Provider.of<AccountProvider>(
                    context,
                  ).accounts.length.toString(),
                ),
                const Divider(height: 1, indent: 16),
                _buildInfoTile(
                  Icons.category_rounded,
                  'Категоритай данс',
                  Provider.of<AccountProvider>(
                    context,
                  ).accounts.where((a) => a.isDefined).length.toString(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Clear Data Section
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
              ),
              title: const Text('Бүх өгөгдөл устгах'),
              subtitle: const Text('Энэ үйлдлийг буцаах боломжгүй'),
              onTap: _showClearDataDialog,
            ),
          ),

          if (_isImporting)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Импортлож байна...',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  String _getDatabaseSize() {
    // Simulated database size
    return '1.2';
  }

  Future<void> _loadDemoData() async {
    try {
      setState(() => _isImporting = true);

      // Load accounts from JSON asset
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      final jsonString = await rootBundle.loadString(
        'assets/assigned_accounts_20260507_155802.json',
      );
      await accountProvider.importDefinedAccounts(jsonString);

      // Load transactions from CSV asset
      final csvString = await rootBundle.loadString('assets/2025-10 - Sheet1.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
      );

      await _parseKhanBankCSV(csvData);

      // Refresh data
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
      await Provider.of<AccountProvider>(
        context,
        listen: false,
      ).loadAccounts();

      setState(() => _isImporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demo өгөгдөл амжилттай ачаалагдлаа: $_importedCount шинэ, $_skippedCount давхардсан',
            ),
            backgroundColor: _skippedCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo өгөгдөл ачаалахад алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Бүх өгөгдөл устгах'),
        content: const Text(
          'Энэ үйлдэл нь бүх гүйлгээ, данс, категориудыг устгах болно. Та үүнийг буцаах боломжгүй.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear database
              final db = await DatabaseHelper.instance.database;
              await db.delete('transactions');
              await db.delete('accounts');
              await db.delete('categories');

              // Refresh providers
              await Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).loadTransactions();
              await Provider.of<AccountProvider>(
                context,
                listen: false,
              ).loadAccounts();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Өгөгдөл амжилттай устгагдлаа'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
  }

  Future<void> _parseKhanBankCSV(List<List<dynamic>> csvData) async {
    _importedCount = 0;
    _skippedCount = 0;

    // Get existing transactions to check for duplicates
    final existingTransactions = await DatabaseHelper.instance
        .getAllTransactions();

    // Skip header row (index 0 is headers)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length < 7) continue;

      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[0].toString());

        // Parse the values
        final beginningBalance =
            double.tryParse(row[2].toString().replaceAll(',', '')) ?? 0;
        final expense =
            double.tryParse(row[3].toString().replaceAll(',', '')) ?? 0;
        final income =
            double.tryParse(row[4].toString().replaceAll(',', '')) ?? 0;
        final endingBalance =
            double.tryParse(row[5].toString().replaceAll(',', '')) ?? 0;
        final description = row[6].toString();

        final cleanedDescription = Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).getCleanDescription(description);

        // Extract counterparty account if available
        String? counterpartyAccount;
        String accountNumber;

        if (row.length > 7 && row[7].toString().isNotEmpty) {
          // If counterparty account exists, use it as the account number
          counterpartyAccount = row[7].toString();
          accountNumber = counterpartyAccount;
        } else {
          // No counterparty account, extract from description
          // Check for TRF pattern
          final trfPattern = RegExp(r'^TRF=[A-Z0-9]+-[A-Z0-9]+-(.+)');
          final trfMatch = trfPattern.firstMatch(description);

          if (trfMatch != null) {
            // Extract the part after TRF=...-...-\
            accountNumber = trfMatch.group(1)?.trim() ?? description;
          } else {
            // Use cleaned description as account number
            accountNumber = cleanedDescription.isNotEmpty
                ? cleanedDescription
                : description;
          }

          // Clean up account number (remove any trailing special characters)
          accountNumber = accountNumber
              .replaceAll(RegExp(r'[^\w\s>]+$'), '')
              .trim();

          // If account number is too long, truncate it
          if (accountNumber.length > 50) {
            accountNumber = accountNumber.substring(0, 50);
          }
        }

        // Create transaction object to check for duplicate
        final transaction = Transaction(
          date: date,
          beginningBalance: beginningBalance,
          expense: expense,
          income: income,
          endingBalance: endingBalance,
          description: description,
          cleanedDescription: cleanedDescription,
          counterpartyAccount: counterpartyAccount,
          accountNumber: accountNumber,
          bankType: 'khan',
        );

        // Check for duplicate
        if (_isDuplicateTransaction(transaction, existingTransactions)) {
          _skippedCount++;
          print('Skipped duplicate transaction: $date - $description');
          continue;
        }

        // Check if account exists, if not create it
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        var account = accountProvider.getAccountByNumber(accountNumber);
        if (account == null) {
          // Generate a readable name from the account number
          String accountName;
          if (counterpartyAccount != null) {
            accountName = 'Хаан Банк - $counterpartyAccount';
          } else {
            // For description-based accounts, create a shorter name
            final nameParts = accountNumber.split(RegExp(r'[>\s]+'));
            if (nameParts.length > 1) {
              accountName = 'Хаан - ${nameParts.take(2).join(' ')}';
            } else {
              accountName =
                  'Хаан - ${accountNumber.substring(0, accountNumber.length > 15 ? 15 : accountNumber.length)}';
            }
          }

          account = Account(
            accountNumber: accountNumber,
            name: accountName,
            description: 'Хаан банкны данс',
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
            isDefined: false,
          );
          await accountProvider.addAccount(account);
        }

        await DatabaseHelper.instance.insertTransaction(transaction);
        _importedCount++;
      } catch (e) {
        print('Error parsing row $i: $e');
      }
    }

    print('Import complete: $_importedCount imported, $_skippedCount skipped');
  }
}
