// lib/services/golomt_bank_parser.dart
import 'dart:io';
import 'package:excel/excel.dart';
import '../models/transaction.dart';

class GolomtBankParser {
  static List<BankTransaction> parseExcel(File file) {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    
    List<BankTransaction> transactions = [];
    
    // Get the sheet by name or first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (key) => key.contains('Operative') || key.contains('Sheet'),
      orElse: () => excel.tables.keys.first,
    );
    
    var sheet = excel.tables[sheetName]!;
    var rows = sheet.rows;
    
    // Find the starting row (skip headers)
    int startRow = 0;
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].isNotEmpty && 
          rows[i][0]?.value.toString().contains('202') == true) {
        startRow = i;
        break;
      }
    }
    
    // Parse each transaction row
    for (int i = startRow; i < rows.length; i++) {
      var row = rows[i];
      
      if (row.length >= 6 && row[0] != null && row[0]!.value.toString().isNotEmpty) {
        try {
          String? dateStr = row[0]?.value?.toString();
          if (dateStr == null || !dateStr.contains('202')) continue;
          
          String? debitStr = row[2]?.value?.toString();
          String? creditStr = row[3]?.value?.toString();
          String? balanceStr = row[4]?.value?.toString();
          String? description = row[5]?.value?.toString();
          String? relatedAccount = row.length > 6 ? row[6]?.value?.toString() : null;
          
          // Parse date
          DateTime date;
          if (dateStr.contains('T')) {
            date = DateTime.parse(dateStr.split('.')[0]); // Remove milliseconds
          } else {
            date = DateTime.parse(dateStr);
          }
          
          // Parse amounts
          double debitAmount = _parseAmount(debitStr ?? '0');
          double creditAmount = _parseAmount(creditStr ?? '0');
          double balanceAmount = _parseAmount(balanceStr ?? '0');
          
          // Extract account number from description if available
          String accountFromDesc = _extractAccountFromDescription(description ?? '');
          
          transactions.add(BankTransaction(
            bankName: 'Golomt Bank',
            date: date,
            description: description ?? 'No description',
            debit: debitAmount,
            credit: creditAmount,
            balance: balanceAmount,
            accountNumber: '1805176793',
            relatedAccount: relatedAccount?.isNotEmpty == true ? relatedAccount : accountFromDesc,
            transactionValue: description,
          ));
        } catch (e) {
          print('Error parsing row $i: $e');
          print('Row data: ${row.map((cell) => cell?.value).toList()}');
        }
      }
    }
    
    print('Parsed ${transactions.length} transactions from Golomt Bank');
    return transactions;
  }

  static double _parseAmount(String amountStr) {
    try {
      // Remove any commas and whitespace
      String cleaned = amountStr.replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static String _extractAccountFromDescription(String description) {
    // Try to find account number in description
    RegExp accountPattern = RegExp(r'\d{9,12}');
    var match = accountPattern.firstMatch(description);
    return match?.group(0) ?? '';
  }
}