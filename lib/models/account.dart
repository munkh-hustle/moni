// lib/models/account.dart
import 'dart:ui';

class Account {
  int? id;
  String accountNumber;
  String name;
  String? description;
  Color color;
  bool isDefined;
  String? category; // Add this field

  Account({
    this.id,
    required this.accountNumber,
    required this.name,
    this.description,
    required this.color,
    this.isDefined = false,
    this.category, // Add this
  });

  Map<String, dynamic> toMap() {
    final map = {
      'accountNumber': accountNumber,
      'name': name,
      'description': description,
      'color': color.value,
      'isDefined': isDefined ? 1 : 0,
      'category': category,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      accountNumber: map['accountNumber'],
      name: map['name'],
      description: map['description'],
      color: Color(map['color']),
      isDefined: map['isDefined'] == 1,
      category: map['category'], // Add this
    );
  }
}
