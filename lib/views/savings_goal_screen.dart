// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, unused_local_variable, deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/savings_entry.dart';
import '../models/savings_goal.dart';
import '../providers/savings_entry_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../widgets/saving_goal_summary.dart';

class SavingGoalScreen extends ConsumerStatefulWidget {
  const SavingGoalScreen({super.key});

  @override
  ConsumerState<SavingGoalScreen> createState() => _SavingGoalScreenState();
}

class _SavingGoalScreenState extends ConsumerState<SavingGoalScreen> {
  final _goalFormKey = GlobalKey<FormState>();
  final _entryFormKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _entryAmountController = TextEditingController();
  DateTime? _deadline;
  DateTime? _entryDate;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isSavingEntry = false;

  @override
  void dispose() {
    _targetController.dispose();
    _entryAmountController.dispose();
    super.dispose();
  }

  void _initializeFields(SavingsGoal? goal) {
    if (!_initialized && goal != null) {
      _targetController.text = goal.targetAmount.toStringAsFixed(2);
      _deadline = goal.deadline;
      _initialized = true;
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  Future<void> _saveGoal([SavingsGoal? existing]) async {
    if (!_goalFormKey.currentState!.validate() || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all goal fields.')),
      );
      return;
    }
    final target = double.parse(_targetController.text.trim());
    final goal = SavingsGoal(
      id: existing?.id,
      targetAmount: target,
      deadline: _deadline!,
    );
    if (existing == null) {
      await ref.read(savingsGoalProvider.notifier).addGoal(goal);
    } else {
      await ref
          .read(savingsGoalProvider.notifier)
          .updateGoal(goal, existing.id!);
    }
    _initialized = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Goal set!' : 'Goal updated!'),
        ),
      );
    }
  }

  Future<void> _addEntry(int goalId) async {
    if (!_entryFormKey.currentState!.validate() || _entryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all saving fields.')),
      );
      return;
    }
    final amount = double.parse(_entryAmountController.text.trim());
    final entry = SavingsEntry(
      amount: amount,
      date: _entryDate!,
      goalId: goalId,
    );
    await ref.read(savingsEntryProvider(goalId).notifier).addEntry(entry);
    setState(() {
      _entryAmountController.clear();
      _entryDate = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving added!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(savingsGoalProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      body: goalAsync.when(
        data: (goals) {
          final goal = goals.isNotEmpty ? goals.first : null;
          _initializeFields(goal);
          if (goal == null) {
            // First time: show goal setup form
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _goalFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a Savings Goal',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
                        prefixIcon: const Icon(Icons.flag),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter a target amount';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Deadline',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _deadline == null
                                  ? 'Pick a date'
                                  : DateFormat.yMMMd().format(_deadline!),
                              style: textTheme.bodyLarge,
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedScale(
                        scale: _isSaving ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(
                            'Set Goal',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed:
                              _isSaving
                                  ? null
                                  : () async {
                                    setState(() => _isSaving = true);
                                    // ignore: await_only_futures
                                    await _saveGoal();
                                    setState(() => _isSaving = false);
                                  },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // After goal is set: show summary, edit, add entry, and list
          final entriesAsync = ref.watch(savingsEntryProvider(goal.id!));
          final totalSaved = entriesAsync.maybeWhen(
            data:
                (entries) =>
                    entries.fold<double>(0, (sum, e) => sum + e.amount),
            orElse: () => 0.0,
          );
          final percent =
              goal.targetAmount == 0
                  ? 0.0
                  : (totalSaved / goal.targetAmount).clamp(0.0, 1.0);
          const accentPurple = Color(0xFF8B5CF6);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 7,
                          // ignore: deprecated_member_use
                          backgroundColor: accentPurple.withOpacity(0.15),
                          color: accentPurple,
                        ),
                      ),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentPurple,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SavingGoalSummary(
                  target: goal.targetAmount,
                  saved: totalSaved,
                  deadline: goal.deadline,
                ),
                Form(
                  key: _goalFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Goal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter a target amount';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0)
                            return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDeadline,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Deadline',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _deadline == null
                                    ? 'Pick a date'
                                    : DateFormat.yMMMd().format(_deadline!),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveGoal(goal),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Update Goal'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _entryFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Saving',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _entryAmountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter amount';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0)
                            return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickEntryDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _entryDate == null
                                    ? 'Pick a date'
                                    : DateFormat.yMMMd().format(_entryDate!),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedScale(
                          scale: _isSavingEntry ? 0.96 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: ElevatedButton(
                            onPressed:
                                _isSavingEntry
                                    ? null
                                    : () async {
                                      setState(() => _isSavingEntry = true);
                                      await _addEntry(goal.id!);
                                      setState(() => _isSavingEntry = false);
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Add Saving'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Entries',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                entriesAsync.when(
                  data:
                      (entries) =>
                          entries.isEmpty
                              ? const Text('No savings yet.')
                              : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: entries.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final entry = entries[i];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.savings,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: Text(currency.format(entry.amount)),
                                    subtitle: Text(
                                      DateFormat.yMMMd().format(entry.date),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              savingsEntryProvider(
                                                goal.id!,
                                              ).notifier,
                                            )
                                            .deleteEntry(entry.id!);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Entry deleted!'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}
