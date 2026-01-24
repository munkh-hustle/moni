// lib/models/account.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AccountCategory {
  final String accountNumber;
  final String category;
  final String name;
  final Color color;

  AccountCategory({
    required this.accountNumber,
    required this.category,
    required this.name,
    required this.color,
  });

  static final List<AccountCategory> predefinedCategories = [
    AccountCategory(
      accountNumber: '102400346031',
      category: 'family',
      name: 'Mother',
      color: Colors.pink,
    ),
    AccountCategory(
      accountNumber: '5026600989',
      category: 'education',
      name: 'Daughter School',
      color: Colors.blue,
    ),
    AccountCategory(
      accountNumber: '5926409867',
      category: 'personal',
      name: 'Personal Transfer',
      color: Colors.green,
    ),
    AccountCategory(
      accountNumber: '8365110496',
      category: 'business',
      name: 'Business',
      color: Colors.orange,
    ),
    AccountCategory(
      accountNumber: '5133067388',
      category: 'investment',
      name: 'Investment',
      color: Colors.purple,
    ),
    AccountCategory(
      accountNumber: '5111793576',
      category: 'shopping',
      name: 'Shopping',
      color: Colors.teal,
    ),
    AccountCategory(
      accountNumber: '5219106107',
      category: 'utilities',
      name: 'Utilities',
      color: Colors.brown,
    ),
    AccountCategory(
      accountNumber: '5038003478',
      category: 'subscriptions',
      name: 'Subscriptions',
      color: Colors.indigo,
    ),
  ];

  static AccountCategory? getCategoryForAccount(String accountNumber) {
    return predefinedCategories.firstWhere(
      (cat) => accountNumber.contains(cat.accountNumber),
      orElse: () => AccountCategory(
        accountNumber: accountNumber,
        category: 'other',
        name: 'Unknown',
        color: Colors.grey,
      ),
    );
  }

  static List<AccountCategory> getAllCategories() {
    return predefinedCategories;
  }
}