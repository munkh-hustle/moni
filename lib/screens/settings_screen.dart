// lib/screens/settings_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
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
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'CSV ИМПОРТ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildImportCard(
            'Хаан Банк',
            'icons/khanbank.png',
            Colors.blue,
            () => _importCSV('khan'),
          ),
          const SizedBox(height: 8),
          _buildImportCard(
            'Голомт Банк',
            'icons/golomt.png',
            Colors.deepPurple,
            () => _importCSV('golomt'),
          ),
          const SizedBox(height: 24),
          const Text(
            'CSV ЭКСПОРТ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildExportCard(),
          const SizedBox(height: 24),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
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

  Widget _buildImportCard(
    String bank,
    String iconPath,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CSV файл сонгох',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.upload_file_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      child: Column(
        children: [
          _buildExportTile(
            'Хаан Банк формат',
            Icons.download_rounded,
            Colors.blue,
            () => _exportCSV('khan'),
          ),
          const Divider(height: 1, indent: 16),
          _buildExportTile(
            'Голомт Банк формат',
            Icons.download_rounded,
            Colors.deepPurple,
            () => _exportCSV('golomt'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.share_rounded),
      onTap: onTap,
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

  Future<void> _importCSV(String bankType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() => _isImporting = true);

        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<List<dynamic>> csvData = const CsvToListConverter().convert(
          content,
        );

        if (bankType == 'khan') {
          await _parseKhanBankCSV(csvData);
        } else if (bankType == 'golomt') {
          await _parseGolomtBankCSV(csvData);
        }

        // Refresh data
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).loadTransactions();
        await Provider.of<AccountProvider>(
          context,
          listen: false,
        ).loadAccounts();

        if (mounted) {
          setState(() => _isImporting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Амжилттай импортлов'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseKhanBankCSV(List<List<dynamic>> csvData) async {
    // Skip header row (index 0 is headers)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length < 7) continue;

      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[0].toString());

        // Get the account number from the header or use a default
        final accountNumber = 'KHAN_5429445212';

        // Parse the values correctly - FIXED COLUMN INDICES
        final beginningBalance =
            double.tryParse(row[2].toString().replaceAll(',', '')) ??
            0; // Changed from row[1] to row[2]
        final expense =
            double.tryParse(row[3].toString().replaceAll(',', '')) ??
            0; // Changed from row[2] to row[3]
        final income =
            double.tryParse(row[4].toString().replaceAll(',', '')) ??
            0; // Changed from row[3] to row[4]
        final endingBalance =
            double.tryParse(row[5].toString().replaceAll(',', '')) ??
            0; // Changed from row[4] to row[5]
        final description = row[6].toString(); // Changed from row[5] to row[6]

        // Extract counterparty account if available
        String? counterpartyAccount;
        if (row.length > 7 && row[7].toString().isNotEmpty) {
          // Changed from row[6] to row[7]
          counterpartyAccount = row[7].toString();
        }

        // Check if account exists, if not create it
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        var account = accountProvider.getAccountByNumber(accountNumber);
        if (account == null) {
          account = Account(
            accountNumber: accountNumber,
            name: 'Хаан Банк',
            description: 'Хаан банкны данс',
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
            isDefined: false,
          );
          await accountProvider.addAccount(account);
        }

        final transaction = Transaction(
          date: date,
          beginningBalance: beginningBalance,
          expense: expense,
          income: income,
          endingBalance: endingBalance,
          description: description,
          counterpartyAccount: counterpartyAccount,
          accountNumber: accountNumber,
          bankType: 'khan',
        );

        await DatabaseHelper.instance.insertTransaction(transaction);
      } catch (e) {
        print('Error parsing row $i: $e');
      }
    }
  }

  Future<void> _parseGolomtBankCSV(List<List<dynamic>> csvData) async {
    // Find the start of transaction data
    int startRow = 0;
    for (int i = 0; i < csvData.length; i++) {
      if (csvData[i].isNotEmpty && csvData[i][0] == 'Гүйлгээний огноо') {
        startRow = i + 1;
        break;
      }
    }

    for (int i = startRow; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.length < 7 || row[0].toString().isEmpty) continue;

      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(row[0].toString());
        final beginningBalance = double.tryParse(row[1].toString()) ?? 0;
        final expense = double.tryParse(row[2].toString()) ?? 0;
        final income = double.tryParse(row[3].toString()) ?? 0;
        final endingBalance = double.tryParse(row[4].toString()) ?? 0;
        final description = row[5].toString();
        final counterpartyAccount = row.length > 6 ? row[6].toString() : null;

        // Extract account number from first row or provide default
        final accountNumber = 'GOLOMT_1805176793';

        // Check if account exists, if not create it
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        var account = accountProvider.getAccountByNumber(accountNumber);
        if (account == null) {
          account = Account(
            accountNumber: accountNumber,
            name: 'Голомт Банк',
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
            isDefined: false,
          );
          await accountProvider.addAccount(account);
        }

        final transaction = Transaction(
          date: date,
          beginningBalance: beginningBalance,
          expense: expense,
          income: income,
          endingBalance: endingBalance,
          description: description,
          counterpartyAccount: counterpartyAccount,
          accountNumber: accountNumber,
          bankType: 'golomt',
        );

        await DatabaseHelper.instance.insertTransaction(transaction);
      } catch (e) {
        print('Error parsing row: $e');
      }
    }
  }

  Future<void> _exportCSV(String bankType) async {
    try {
      final transactions = Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).transactions.where((t) => t.bankType == bankType).toList();

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Экспортлох өгөгдөл байхгүй'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<List<dynamic>> rows = [];

      if (bankType == 'khan') {
        rows.add([
          'Гүйлгээний огноо',
          'Эхний үлдэгдэл',
          'Зарлага',
          'Орлого',
          'Эцсийн үлдэгдэл',
          'Гүйлгээний утга',
          'Харьцсан данс',
        ]);
        for (var t in transactions) {
          rows.add([
            DateFormat('yyyy-MM-dd HH:mm:ss').format(t.date),
            t.beginningBalance.toStringAsFixed(2),
            t.expense.toStringAsFixed(2),
            t.income.toStringAsFixed(2),
            t.endingBalance.toStringAsFixed(2),
            t.description,
            t.counterpartyAccount ?? '',
          ]);
        }
      } else {
        rows.add([
          'Гүйлгээний огноо',
          'Салбар',
          'Эхний үлдэгдэл',
          'Дебит гүйлгээ',
          'Кредит гүйлгээ',
          'Эцсийн үлдэгдэл',
          'Гүйлгээний утга',
          'Харьцсан данс',
        ]);
        for (var t in transactions) {
          rows.add([
            DateFormat('yyyy-MM-dd HH:mm:ss').format(t.date),
            '',
            t.beginningBalance.toStringAsFixed(2),
            t.expense.toStringAsFixed(2),
            t.income.toStringAsFixed(2),
            t.endingBalance.toStringAsFixed(2),
            t.description,
            t.counterpartyAccount ?? '',
          ]);
        }
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Save to temporary file and share
      final directory = await Directory.systemTemp;
      final file = File(
        '${directory.path}/bank_statement_${bankType}_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)], text: 'Банкны хуулга');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа гарлаа: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
}
