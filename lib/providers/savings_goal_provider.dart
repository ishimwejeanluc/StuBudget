import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_goal.dart';
import '../services/savings_goal_service.dart';

class SavingsGoalNotifier extends StateNotifier<AsyncValue<List<SavingsGoal>>> {
  SavingsGoalNotifier() : super(const AsyncValue.loading()) {
    fetchGoals();
  }

  final _service = SavingsGoalService();

  Future<void> fetchGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _service.fetchGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _service.insertGoal(goal);
    await fetchGoals();
  }

  Future<void> updateGoal(SavingsGoal goal, int id) async {
    await _service.updateGoal(goal, id);
    await fetchGoals();
  }

  Future<void> deleteGoal(int id) async {
    await _service.deleteGoal(id);
    await fetchGoals();
  }
}

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalNotifier, AsyncValue<List<SavingsGoal>>>(
      (ref) => SavingsGoalNotifier(),
    );
