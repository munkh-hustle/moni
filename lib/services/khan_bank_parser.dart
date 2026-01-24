// lib/services/khan_bank_parser.dart
import 'dart:io';
import 'package:excel/excel.dart';
import '../models/transaction.dart';

class KhanBankParser {
  static List<BankTransaction> parseExcel(File file) {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    
    List<BankTransaction> transactions = [];
    
    // Assuming the data is in the first sheet
    var sheet = excel.tables.keys.first;
    var rows = excel.tables[sheet]!.rows;
    
    // Skip header rows (first 2 rows)
    for (int i = 2; i < rows.length; i++) {
      var row = rows[i];
      
      // Check if row has enough data
      if (row.length >= 10 && row[0] != null && row[0]!.value.toString().isNotEmpty) {
        try {
          String dateStr = row[0]!.value.toString();
          String branch = row[1]?.value?.toString() ?? '';
          String initialBalance = row[2]?.value?.toString() ?? '0';
          String debit = row[3]?.value?.toString() ?? '0';
          String credit = row[4]?.value?.toString() ?? '0';
          String finalBalance = row[5]?.value?.toString() ?? '0';
          String description = row[6]?.value?.toString() ?? '';
          String relatedAccount = row[7]?.value?.toString() ?? '';
          
          DateTime date = DateTime.parse(dateStr);
          double debitAmount = double.tryParse(debit) ?? 0;
          double creditAmount = double.tryParse(credit) ?? 0;
          double balanceAmount = double.tryParse(finalBalance) ?? 0;
          
          transactions.add(BankTransaction(
            bankName: 'Khan Bank',
            date: date,
            description: description,
            debit: debitAmount,
            credit: creditAmount,
            balance: balanceAmount,
            accountNumber: '5429445212', // Main account from the statement
            relatedAccount: relatedAccount.isNotEmpty ? relatedAccount : null,
            branch: branch.isNotEmpty ? branch : null,
            transactionValue: description,
          ));
        } catch (e) {
          print('Error parsing row $i: $e');
        }
      }
    }
    
    return transactions;
  }
}