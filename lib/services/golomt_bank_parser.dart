import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

import '../models/transaction.dart';

class GolomtBankParser {
  static List<BankTransaction> parseExcel(File file) {
    try {
      // Read file as bytes
      var bytes = file.readAsBytesSync();
      
      // Convert bytes to string to debug
      String fileContent = utf8.decode(bytes);
      
      // Try to parse as CSV first (Golomt exports might be CSV or Excel)
      List<BankTransaction> transactions = [];
      
      // Try multiple parsing strategies
      transactions = _tryParseCSV(fileContent);
      
      if (transactions.isEmpty) {
        transactions = _tryParseExcel(bytes);
      }
      
      print('Parsed ${transactions.length} transactions from Golomt Bank');
      return transactions;
    } catch (e) {
      print('Error parsing Golomt Bank file: $e');
      return [];
    }
  }

  static List<BankTransaction> _tryParseCSV(String fileContent) {
    List<BankTransaction> transactions = [];
    
    try {
      List<String> lines = fileContent.split('\n');
      
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Skip header lines
        if (line.contains('Хуулганы огноо') || 
            line.contains('Гүйлгээний огноо') ||
            line.startsWith('"')) {
          continue;
        }
        
        // Split by comma or semicolon
        List<String> parts = line.split(',');
        if (parts.length < 6) {
          parts = line.split(';');
        }
        
        if (parts.length >= 6) {
          try {
            String dateStr = parts[0].replaceAll('"', '').trim();
            String debitStr = parts[2].replaceAll('"', '').trim();
            String creditStr = parts[3].replaceAll('"', '').trim();
            String balanceStr = parts[4].replaceAll('"', '').trim();
            String description = parts[5].replaceAll('"', '').trim();
            String relatedAccount = parts.length > 6 ? parts[6].replaceAll('"', '').trim() : '';
            
            DateTime date = _parseDate(dateStr);
            double debitAmount = _parseAmount(debitStr);
            double creditAmount = _parseAmount(creditStr);
            double balanceAmount = _parseAmount(balanceStr);
            
            transactions.add(BankTransaction(
              bankName: 'Golomt Bank',
              date: date,
              description: description,
              debit: debitAmount,
              credit: creditAmount,
              balance: balanceAmount,
              accountNumber: '1805176793',
              relatedAccount: relatedAccount.isNotEmpty ? relatedAccount : null,
              transactionValue: description,
            ));
          } catch (e) {
            print('Error parsing CSV line: $e\nLine: $line');
          }
        }
      }
    } catch (e) {
      print('Error in CSV parsing: $e');
    }
    
    return transactions;
  }

  static List<BankTransaction> _tryExcelPackage(List<int> bytes) {
    // Alternative approach using simpler parsing
    List<BankTransaction> transactions = [];
    
    try {
      String content = String.fromCharCodes(bytes);
      List<String> lines = content.split('\n');
      
      // Look for transaction patterns
      for (String line in lines) {
        // Look for date pattern (YYYY-MM-DD)
        RegExp datePattern = RegExp(r'\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}');
        var dateMatch = datePattern.firstMatch(line);
        
        if (dateMatch != null) {
          try {
            String dateStr = dateMatch.group(0)!;
            DateTime date = _parseDate(dateStr);
            
            // Extract amounts using patterns
            RegExp amountPattern = RegExp(r'\d+(?:\.\d+)?');
            var amountMatches = amountPattern.allMatches(line).toList();
            
            if (amountMatches.length >= 3) {
              double debitAmount = 0;
              double creditAmount = 0;
              double balanceAmount = 0;
              
              // Try to identify which amount is which based on context
              String lineLower = line.toLowerCase();
              
              // Simple heuristic: look for key words
              for (var match in amountMatches) {
                String amountStr = match.group(0)!;
                double amount = _parseAmount(amountStr);
                
                // Context-based assignment (simplified)
                if (lineLower.contains('зарлаг') || lineLower.contains('debit')) {
                  debitAmount = amount;
                } else if (lineLower.contains('орлог') || lineLower.contains('credit')) {
                  creditAmount = amount;
                } else if (lineLower.contains('үлдэгдэл') || lineLower.contains('balance')) {
                  balanceAmount = amount;
                }
              }
              
              // Extract description (everything after amounts)
              String description = line.substring(dateMatch.end).trim();
              
              transactions.add(BankTransaction(
                bankName: 'Golomt Bank',
                date: date,
                description: description,
                debit: debitAmount,
                credit: creditAmount,
                balance: balanceAmount,
                accountNumber: '1805176793',
                relatedAccount: _extractAccountFromDescription(description),
                transactionValue: description,
              ));
            }
          } catch (e) {
            print('Error parsing line: $e');
          }
        }
      }
    } catch (e) {
      print('Error in alternative parsing: $e');
    }
    
    return transactions;
  }

  static List<BankTransaction> _tryParseExcel(List<int> bytes) {
    try {
      // Try using excel package with error handling
      final excel = Excel.decodeBytes(bytes);
      
      List<BankTransaction> transactions = [];
      
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        
        for (var row in sheet.rows) {
          if (row.isEmpty) continue;
          
          try {
            // Look for date cell
            var dateCell = row[0];
            if (dateCell == null || dateCell.value == null) continue;
            
            String? dateStr = dateCell.value.toString();
            if (!dateStr.contains('202')) continue;
            
            DateTime date = _parseDate(dateStr);
            
            // Get amounts
            double debitAmount = _parseCellValue(row.length > 2 ? row[2] : null);
            double creditAmount = _parseCellValue(row.length > 3 ? row[3] : null);
            double balanceAmount = _parseCellValue(row.length > 4 ? row[4] : null);
            
            String? description = row.length > 5 ? row[5]?.value?.toString() : '';
            String? relatedAccount = row.length > 6 ? row[6]?.value?.toString() : '';
            
            transactions.add(BankTransaction(
              bankName: 'Golomt Bank',
              date: date,
              description: description ?? '',
              debit: debitAmount,
              credit: creditAmount,
              balance: balanceAmount,
              accountNumber: '1805176793',
              relatedAccount: relatedAccount?.isNotEmpty == true ? relatedAccount : null,
              transactionValue: description ?? '',
            ));
          } catch (e) {
            // Skip this row if there's an error
            continue;
          }
        }
      }
      
      return transactions;
    } catch (e) {
      print('Excel package error: $e');
      return [];
    }
  }

  static double _parseCellValue(cell) {
    if (cell == null || cell.value == null) return 0.0;
    
    try {
      if (cell.value is num) {
        return (cell.value as num).toDouble();
      } else if (cell.value is String) {
        return _parseAmount(cell.value as String);
      }
    } catch (e) {
      print('Error parsing cell value: $e');
    }
    
    return 0.0;
  }

  static DateTime _parseDate(String dateStr) {
    try {
      // Handle various date formats
      String cleaned = dateStr.replaceAll('"', '').trim();
      
      // Try ISO format first
      if (cleaned.contains('T')) {
        return DateTime.parse(cleaned.split('.')[0]);
      }
      
      // Try common Mongolian date formats
      if (cleaned.contains('-')) {
        return DateTime.parse(cleaned);
      }
      
      // Fallback: current date
      return DateTime.now();
    } catch (e) {
      print('Error parsing date "$dateStr": $e');
      return DateTime.now();
    }
  }

  static double _parseAmount(String amountStr) {
    try {
      // Remove any non-numeric characters except dots and minus
      String cleaned = amountStr
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .replaceAll('₮', '')
          .replaceAll('MNT', '')
          .replaceAll('"', '')
          .trim();
      
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static String _extractAccountFromDescription(String description) {
    try {
      // Look for account numbers in description
      RegExp accountPattern = RegExp(r'\b\d{8,12}\b');
      var matches = accountPattern.allMatches(description);
      
      for (var match in matches) {
        String account = match.group(0)!;
        // Skip if it looks like a transaction ID or phone number
        if (account.startsWith('0') && account.length <= 10) continue;
        return account;
      }
    } catch (e) {
      print('Error extracting account: $e');
    }
    
    return '';
  }
}