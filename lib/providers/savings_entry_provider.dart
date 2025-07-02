import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_entry.dart';
import '../services/savings_entry_service.dart';

class SavingsEntryNotifier
    extends StateNotifier<AsyncValue<List<SavingsEntry>>> {
  SavingsEntryNotifier(this.goalId) : super(const AsyncValue.loading()) {
    fetchEntries();
  }

  final int goalId;
  final _service = SavingsEntryService();

  Future<void> fetchEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _service.fetchEntries(goalId);
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(SavingsEntry entry) async {
    await _service.insertEntry(entry);
    await fetchEntries();
  }

  Future<void> updateEntry(SavingsEntry entry) async {
    await _service.updateEntry(entry);
    await fetchEntries();
  }

  Future<void> deleteEntry(int id) async {
    await _service.deleteEntry(id);
    await fetchEntries();
  }
}

final savingsEntryProvider = StateNotifierProvider.family<
  SavingsEntryNotifier,
  AsyncValue<List<SavingsEntry>>,
  int
>((ref, goalId) => SavingsEntryNotifier(goalId));
