// ignore_for_file: unused_import

import 'package:flutter/material.dart';

class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? note;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount:
          map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
    };
  }
}
