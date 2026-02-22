// lib/models/account.dart
import 'dart:ui';

class Account {
  int? id;
  String accountNumber;
  String name;
  String? description;
  Color color;
  bool isDefined;

  Account({
    this.id,
    required this.accountNumber,
    required this.name,
    this.description,
    required this.color,
    this.isDefined = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountNumber': accountNumber,
      'name': name,
      'description': description,
      'color': color.value,
      'isDefined': isDefined ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      accountNumber: map['accountNumber'],
      name: map['name'],
      description: map['description'],
      color: Color(map['color']),
      isDefined: map['isDefined'] == 1,
    );
  }
}