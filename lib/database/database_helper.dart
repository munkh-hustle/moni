// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bank_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Increment version to 3
    return await openDatabase(
      path,
      version: 3, // Changed from 2 to 3
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Helper method to check if a column exists in a table
  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.any((row) => row['name'] == columnName);
  }

  // Add this method for handling database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cleanedDescription column to transactions table
      if (!await _columnExists(db, 'transactions', 'cleanedDescription')) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN cleanedDescription TEXT',
        );
      }
    }

    // Add this for version 3
    if (oldVersion < 3) {
      // Add category column to accounts table
      if (!await _columnExists(db, 'accounts', 'category')) {
        await db.execute('ALTER TABLE accounts ADD COLUMN category TEXT');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      beginningBalance REAL NOT NULL,
      expense REAL NOT NULL,
      income REAL NOT NULL,
      endingBalance REAL NOT NULL,
      description TEXT NOT NULL,
      cleanedDescription TEXT,
      counterpartyAccount TEXT,
      accountNumber TEXT NOT NULL,
      bankType TEXT NOT NULL,
      category TEXT,
      isDefined INTEGER DEFAULT 0
    )
  ''');

    // Add category column to accounts table
    await db.execute('''
    CREATE TABLE accounts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      accountNumber TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      color INTEGER NOT NULL,
      isDefined INTEGER DEFAULT 0,
      category TEXT
    )
  ''');

    // Rest of the tables remain the same...
    await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      color INTEGER NOT NULL,
      budget REAL DEFAULT 0
    )
  ''');

    // Insert default categories
    await db.insert(
      'categories',
      Category(name: 'Хоол', color: Color(0xFFFF6B6B), budget: 0).toMap(),
    );
    await db.insert(
      'categories',
      Category(name: 'Тээвэр', color: Color(0xFF4ECDC4), budget: 0).toMap(),
    );
    await db.insert(
      'categories',
      Category(name: 'Зугаа', color: Color(0xFFFFD93D), budget: 0).toMap(),
    );
    await db.insert(
      'categories',
      Category(name: 'Дэлгүүр', color: Color(0xFF6BCB77), budget: 0).toMap(),
    );
    await db.insert(
      'categories',
      Category(name: 'Эрүүл мэнд', color: Color(0xFF9D65C9), budget: 0).toMap(),
    );
    await db.insert(
      'categories',
      Category(name: 'Боловсрол', color: Color(0xFF5D9B9B), budget: 0).toMap(),
    );
  }

  // Transaction methods
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByAccount(
    String accountNumber,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'accountNumber = ?',
      whereArgs: [accountNumber],
      orderBy: 'date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Account methods
  Future<int> insertAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts');
    return result.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccount(String accountNumber) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'accountNumber = ?',
      whereArgs: [accountNumber],
    );
    if (result.isNotEmpty) {
      return Account.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;

    // Create a map without including the id field (it's auto-increment)
    final Map<String, dynamic> updateMap = {
      'accountNumber': account.accountNumber,
      'name': account.name,
      'description': account.description,
      'color': account.color.value,
      'isDefined': account.isDefined ? 1 : 0,
      'category': account
          .category,
    };

    return await db.update(
      'accounts',
      updateMap,
      where: 'accountNumber = ?',
      whereArgs: [account.accountNumber],
    );
  }

  // Category methods
  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
