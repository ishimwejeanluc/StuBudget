// ignore_for_file: deprecated_member_use

import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  Future<int> insertCategory(Category category) async {
    final db = await DatabaseService().db;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> fetchCategories() async {
    final db = await DatabaseService().db;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await DatabaseService().db;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await DatabaseService().db;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertDefaultCategories() async {
    final db = await DatabaseService().db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if (count == 0) {
      final defaultCategories = [
        Category(
          name: 'Food',
          iconCodePoint: Icons.fastfood.codePoint,
          iconFontFamily: Icons.fastfood.fontFamily!,
          colorValue: Colors.orange.value,
        ),
        Category(
          name: 'Transport',
          iconCodePoint: Icons.directions_bus.codePoint,
          iconFontFamily: Icons.directions_bus.fontFamily!,
          colorValue: const Color(0xFF4F90FF).value,
        ),
        Category(
          name: 'Shopping',
          iconCodePoint: Icons.shopping_bag.codePoint,
          iconFontFamily: Icons.shopping_bag.fontFamily!,
          colorValue: Colors.purple.value,
        ),
        Category(
          name: 'Bills',
          iconCodePoint: Icons.receipt_long.codePoint,
          iconFontFamily: Icons.receipt_long.fontFamily!,
          colorValue: Colors.red.value,
        ),
        Category(
          name: 'Entertainment',
          iconCodePoint: Icons.movie.codePoint,
          iconFontFamily: Icons.movie.fontFamily!,
          colorValue: Colors.green.value,
        ),
        Category(
          name: 'Health',
          iconCodePoint: Icons.health_and_safety.codePoint,
          iconFontFamily: Icons.health_and_safety.fontFamily!,
          colorValue: Colors.teal.value,
        ),
        Category(
          name: 'Education',
          iconCodePoint: Icons.school.codePoint,
          iconFontFamily: Icons.school.fontFamily!,
          colorValue: Colors.indigo.value,
        ),
        Category(
          name: 'Other',
          iconCodePoint: Icons.category.codePoint,
          iconFontFamily: Icons.category.fontFamily!,
          colorValue: Colors.grey.value,
        ),
      ];
      for (final cat in defaultCategories) {
        await db.insert('categories', cat.toMap());
      }
    }
  }
}
