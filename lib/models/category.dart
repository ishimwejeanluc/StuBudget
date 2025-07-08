import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final int colorValue;

  Category({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);
  Color get color => Color(colorValue);

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['icon'] as int,
      iconFontFamily: map['iconFontFamily'] as String,
      colorValue: map['color'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'color': colorValue,
    };
  }
}
