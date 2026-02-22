// lib/models/category.dart
import 'dart:ui';

class Category {
  int? id;
  String name;
  Color color;
  double budget;

  Category({
    this.id,
    required this.name,
    required this.color,
    this.budget = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'budget': budget,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      budget: map['budget'],
    );
  }
}