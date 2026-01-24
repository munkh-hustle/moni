// lib/services/database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseService {
  static Database? _database;

  static Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'moni_database.db'),
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bankName TEXT,
            date TEXT,
            description TEXT,
            debit REAL,
            credit REAL,
            balance REAL,
            accountNumber TEXT,
            relatedAccount TEXT,
            branch TEXT,
            transactionValue TEXT
          )
          ''',
        );
      },
      version: 1,
    );
  }

  static Future<void> insertTransaction(BankTransaction transaction) async {
    await _database?.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> insertTransactions(List<BankTransaction> transactions) async {
    final batch = _database!.batch();
    for (var transaction in transactions) {
      batch.insert('transactions', transaction.toMap());
    }
    await batch.commit();
  }

  static Future<List<BankTransaction>> getTransactions() async {
    final List<Map<String, dynamic>> maps = 
        await _database!.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return BankTransaction.fromMap(maps[i]);
    });
  }

  static Future<List<BankTransaction>> getTransactionsByAccount(String accountNumber) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: 'accountNumber = ? OR relatedAccount = ?',
      whereArgs: [accountNumber, accountNumber],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return BankTransaction.fromMap(maps[i]);
    });
  }

  static Future<Map<String, dynamic>> getSpendingSummary() async {
    final transactions = await getTransactions();
    
    double totalDebit = 0;
    double totalCredit = 0;
    Map<String, double> spendingByAccount = {};
    
    for (var transaction in transactions) {
      totalDebit += transaction.debit;
      totalCredit += transaction.credit;
      
      if (transaction.debit > 0) {
        final account = transaction.relatedAccount ?? transaction.accountNumber;
        spendingByAccount[account] = (spendingByAccount[account] ?? 0) + transaction.debit;
      }
    }
    
    return {
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'spendingByAccount': spendingByAccount,
      'transactionCount': transactions.length,
    };
  }

  static Future<void> clearAllTransactions() async {
    await _database!.delete('transactions');
  }
}