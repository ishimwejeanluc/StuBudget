import '../models/savings_goal.dart';
import 'database_service.dart';

class SavingsGoalService {
  static final SavingsGoalService _instance = SavingsGoalService._internal();
  factory SavingsGoalService() => _instance;
  SavingsGoalService._internal();

  Future<int> insertGoal(SavingsGoal goal) async {
    final db = await DatabaseService().db;
    return await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoal>> fetchGoals() async {
    final db = await DatabaseService().db;
    final maps = await db.query('savings_goals', orderBy: 'deadline ASC');
    return maps.map((e) => SavingsGoal.fromMap(e)).toList();
  }

  Future<int> updateGoal(SavingsGoal goal, int id) async {
    final db = await DatabaseService().db;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await DatabaseService().db;
    return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
