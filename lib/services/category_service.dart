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
        Category(name: 'Food', icon: Icons.fastfood, color: Colors.orange),
        Category(
          name: 'Transport',
          icon: Icons.directions_bus,
          color: const Color(0xFF4F90FF),
        ),
        Category(
          name: 'Shopping',
          icon: Icons.shopping_bag,
          color: Colors.purple,
        ),
        Category(name: 'Bills', icon: Icons.receipt_long, color: Colors.red),
        Category(name: 'Entertainment', icon: Icons.movie, color: Colors.green),
        Category(
          name: 'Health',
          icon: Icons.health_and_safety,
          color: Colors.teal,
        ),
        Category(name: 'Education', icon: Icons.school, color: Colors.indigo),
        Category(name: 'Other', icon: Icons.category, color: Colors.grey),
      ];
      for (final cat in defaultCategories) {
        await db.insert('categories', cat.toMap());
      }
    }
  }
}
