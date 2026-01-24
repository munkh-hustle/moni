// lib\services\account_database.dart
import 'dart:ui';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';

class AccountDatabaseService {
  static Database? _database;

  static Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'accounts_database.db'),
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            accountNumber TEXT UNIQUE,
            category TEXT,
            name TEXT,
            colorValue INTEGER,
            isActive INTEGER DEFAULT 1
          )
          ''',
        );
      },
      version: 1,
    );
    
    // Insert default categories if not exists
    await _insertDefaultCategories();
  }

  static Future<void> _insertDefaultCategories() async {
    for (var category in AccountCategory.predefinedCategories) {
      await insertAccount(category);
    }
  }

  static Future<void> insertAccount(AccountCategory account) async {
    await _database?.insert(
      'accounts',
      {
        'accountNumber': account.accountNumber,
        'category': account.category,
        'name': account.name,
        'colorValue': account.color.value,
        'isActive': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<AccountCategory>> getAccounts() async {
    final List<Map<String, dynamic>> maps = 
        await _database!.query('accounts', where: 'isActive = 1');
    
    return List.generate(maps.length, (i) {
      return AccountCategory(
        accountNumber: maps[i]['accountNumber'],
        category: maps[i]['category'],
        name: maps[i]['name'],
        color: Color(maps[i]['colorValue']),
      );
    });
  }

  static Future<void> updateAccount(AccountCategory account) async {
    await _database?.update(
      'accounts',
      {
        'category': account.category,
        'name': account.name,
        'colorValue': account.color.value,
      },
      where: 'accountNumber = ?',
      whereArgs: [account.accountNumber],
    );
  }

  static Future<void> deleteAccount(String accountNumber) async {
    await _database?.delete(
      'accounts',
      where: 'accountNumber = ?',
      whereArgs: [accountNumber],
    );
  }

  static Future<void> toggleAccount(String accountNumber, bool isActive) async {
    await _database?.update(
      'accounts',
      {
        'isActive': isActive ? 1 : 0,
      },
      where: 'accountNumber = ?',
      whereArgs: [accountNumber],
    );
  }

  static Future<AccountCategory?> getAccountByNumber(String accountNumber) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'accounts',
      where: 'accountNumber = ? AND isActive = 1',
      whereArgs: [accountNumber],
    );
    
    if (maps.isNotEmpty) {
      return AccountCategory(
        accountNumber: maps[0]['accountNumber'],
        category: maps[0]['category'],
        name: maps[0]['name'],
        color: Color(maps[0]['colorValue']),
      );
    }
    return null;
  }

  static Future<List<AccountCategory>> searchAccounts(String query) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'accounts',
      where: '(accountNumber LIKE ? OR name LIKE ? OR category LIKE ?) AND isActive = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      return AccountCategory(
        accountNumber: maps[i]['accountNumber'],
        category: maps[i]['category'],
        name: maps[i]['name'],
        color: Color(maps[i]['colorValue']),
      );
    });
  }
}