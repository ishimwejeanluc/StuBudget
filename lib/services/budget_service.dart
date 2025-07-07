import 'package:sqflite/sqflite.dart';
import '../models/budget.dart';
import 'database_service.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  Future<int> upsertBudget(Budget budget) async {
    final db = await DatabaseService().db;
    if (budget.id != null) {
      return await db.update(
        'budget',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    } else {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM budget'),
      );
      if (count == 0) {
        return await db.insert('budget', budget.toMap());
      } else {
        // Fetch the existing budget row to get its id
        final maps = await db.query('budget', limit: 1);
        if (maps.isNotEmpty) {
          final id = maps.first['id'] as int;
          return await db.update(
            'budget',
            budget.toMap(),
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          return await db.insert('budget', budget.toMap());
        }
      }
    }
  }

  Future<Budget?> fetchBudget() async {
    final db = await DatabaseService().db;
    final maps = await db.query('budget', limit: 1);
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  Future<double> fetchExpensesTotal() async {
    final db = await DatabaseService().db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses',
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    if (total is int) return total.toDouble();
    return total as double;
  }

  Future<void> resetAll() async {
    final db = await DatabaseService().db;
    await db.delete('expenses');
    await db.delete('budget');
    await db.delete('savings_goals');
  }
}
 