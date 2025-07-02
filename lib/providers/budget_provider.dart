import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  BudgetNotifier() : super(const AsyncValue.loading()) {
    fetchBudget();
  }

  final _service = BudgetService();

  Future<void> fetchBudget() async {
    state = const AsyncValue.loading();
    try {
      final budget = await _service.fetchBudget();
      state = AsyncValue.data(budget);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upsertBudget(Budget budget) async {
    await _service.upsertBudget(budget);
    await fetchBudget();
  }

  Future<void> updateCurrentSpending() async {
    // Fetch all expenses and sum them
    final expenses = await _service.fetchExpensesTotal();
    final current = state.value;
    if (current != null) {
      final updated = Budget(
        id: current.id,
        monthlyLimit: current.monthlyLimit,
        currentSpending: expenses,
      );
      await _service.upsertBudget(updated);
      await fetchBudget();
    }
  }
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>(
      (ref) => BudgetNotifier(),
    );
