import '../models/expense.dart';
import 'database_service.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  Future<int> insertExpense(Expense expense) async {
    final db = await DatabaseService().db;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> fetchExpenses() async {
    final db = await DatabaseService().db;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await DatabaseService().db;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await DatabaseService().db;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
} 