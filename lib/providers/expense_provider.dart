import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'budget_provider.dart';

class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  ExpenseNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  final _service = ExpenseService();

  Future<void> fetchExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _service.fetchExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    await _service.insertExpense(expense);
    await fetchExpenses();
    // Update budget's currentSpending
    final budgetNotifier = ref.read(budgetProvider.notifier);
    await budgetNotifier.updateCurrentSpending();
  }

  Future<void> updateExpense(Expense expense) async {
    await _service.updateExpense(expense);
    await fetchExpenses();
    final budgetNotifier = ref.read(budgetProvider.notifier);
    await budgetNotifier.updateCurrentSpending();
  }

  Future<void> deleteExpense(int id) async {
    await _service.deleteExpense(id);
    await fetchExpenses();
    final budgetNotifier = ref.read(budgetProvider.notifier);
    await budgetNotifier.updateCurrentSpending();
  }
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>(
      (ref) => ExpenseNotifier(ref),
    );
