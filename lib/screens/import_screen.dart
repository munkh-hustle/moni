// lib/screens/import_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moni/models/transaction.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/transaction_provider.dart';
import '../services/khan_bank_parser.dart';
import '../services/golomt_bank_parser.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String _statusMessage = '';
  int _importedCount = 0;

  Future<void> _importBankFile(bool isKhanBank) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _isImporting = true;
          _statusMessage = 'Parsing file...';
        });

        File file = File(result.files.single.path!);
        List<BankTransaction> transactions;

        if (isKhanBank) {
          transactions = KhanBankParser.parseExcel(file);
        } else {
          transactions = GolomtBankParser.parseExcel(file);
        }

        setState(() {
          _statusMessage = 'Importing ${transactions.length} transactions...';
        });

        await context.read<TransactionProvider>().addTransactions(transactions);

        setState(() {
          _isImporting = false;
          _importedCount = transactions.length;
          _statusMessage = 'Successfully imported ${transactions.length} transactions!';
        });

        // Clear message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = '';
            });
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
                      'Supported formats: Excel (.xlsx, .xls)',
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
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_statusMessage)),
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
                    Text('3. Export as Excel format'),
                    Text('4. Import the file here'),
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