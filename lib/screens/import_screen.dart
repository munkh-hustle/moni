import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moni/models/transaction.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/transaction_provider.dart';
import '../services/khan_bank_parser.dart';
import '../services/golomt_bank_parser.dart';
import '../screens/unassigned_accounts_screen.dart'; // Add this import

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String _statusMessage = '';
  int _importedCount = 0;
  bool _hasUnassignedAccounts = false; // Add this

  Future<void> _importBankFile(bool isKhanBank) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'], // Add csv support
      );

      if (result != null) {
        setState(() {
          _isImporting = true;
          _statusMessage = 'Reading file...';
        });

        File file = File(result.files.single.path!);
        List<BankTransaction> transactions;

        if (isKhanBank) {
          _statusMessage = 'Parsing Khan Bank statement...';
          transactions = KhanBankParser.parseExcel(file);
        } else {
          _statusMessage = 'Parsing Golomt Bank statement...';
          transactions = GolomtBankParser.parseExcel(file);
        }

        if (transactions.isEmpty) {
          setState(() {
            _isImporting = false;
            _statusMessage = 'No transactions found in the file. Please check the format.';
          });
          return;
        }

        setState(() {
          _statusMessage = 'Importing ${transactions.length} transactions...';
        });

        await context.read<TransactionProvider>().addTransactions(transactions);

        // Check for unassigned accounts
        final transactionProvider = context.read<TransactionProvider>();
        final unassignedAccounts = transactionProvider.getSpendingByAccount();
        
        // Simple check: if we have many accounts and only few are categorized
        _hasUnassignedAccounts = unassignedAccounts.length > 5; // Adjust threshold as needed

        setState(() {
          _isImporting = false;
          _importedCount = transactions.length;
          _statusMessage = 'Successfully imported ${transactions.length} transactions!';
          
          if (_hasUnassignedAccounts) {
            _statusMessage += '\nFound unassigned accounts. Would you like to categorize them?';
          }
        });

        // Clear message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = '';
            });
            
            // If there are unassigned accounts, ask user
            if (_hasUnassignedAccounts && mounted) {
              _showUnassignedAccountsPrompt();
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _showUnassignedAccountsPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unassigned Accounts Detected'),
        content: const Text(
          'We found several accounts in your transactions that are not categorized. '
          'Would you like to assign categories to them now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnassignedAccountsScreen(),
                ),
              );
            },
            child: const Text('Assign Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Bank Statements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, size: 60, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text(
                      'Import your bank statements',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Supported formats: Excel (.xlsx, .xls), CSV',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton.icon(
              onPressed: _isImporting ? null : () => _importBankFile(true),
              icon: const Icon(Icons.account_balance),
              label: const Text('Import Khan Bank Statement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isImporting ? null : () => _importBankFile(false),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Import Golomt Bank Statement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[800],
              ),
            ),
            
            const SizedBox(height: 30),
            
            if (_isImporting)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_statusMessage),
                ],
              ),
            
            if (_statusMessage.isNotEmpty && !_isImporting)
              Card(
                color: _hasUnassignedAccounts ? Colors.amber[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasUnassignedAccounts ? Icons.warning : Icons.check_circle,
                            color: _hasUnassignedAccounts ? Colors.amber : Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _hasUnassignedAccounts ? Colors.amber[800] : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_hasUnassignedAccounts)
                        const SizedBox(height: 10),
                      if (_hasUnassignedAccounts)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UnassignedAccountsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          child: const Text('Review Unassigned Accounts'),
                        ),
                    ],
                  ),
                ),
              ),
            
            const Spacer(),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to export statements:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('1. Login to your bank\'s online banking'),
                    Text('2. Go to Account Statements'),
                    Text('3. Select date range'),
                    Text('4. Export as Excel or CSV format'),
                    Text('5. Import the file here'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}