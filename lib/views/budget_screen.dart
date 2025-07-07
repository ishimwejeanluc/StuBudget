// ignore_for_file: unused_local_variable, prefer_interpolation_to_compose_strings, deprecated_member_use, curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../main.dart'; // For NotificationsService

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  bool _isSaving = false;
  bool _notifiedOverBudget = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final expenses = ref.watch(expenseProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');
    double currentSpending = 0;
    expenses.whenData((list) {
      currentSpending = list.fold(0, (sum, e) => sum + e.amount);
    });

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final palette = {
      'primary': colorScheme.primary,
      'danger': Colors.redAccent,
      'card': colorScheme.surface,
      'shadow': isDark ? Colors.black26 : const Color(0x11000000),
    };

    // Overspending notification logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = budget.asData?.value;
      if (b != null &&
          b.monthlyLimit > 0 &&
          b.currentSpending > b.monthlyLimit) {
        if (!_notifiedOverBudget) {
          NotificationsService.showOverspendingAlert(
            b.currentSpending,
            b.monthlyLimit,
          );
          _notifiedOverBudget = true;
        }
      } else {
        _notifiedOverBudget = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Monthly Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: budget.when(
          data: (b) {
            final double limit = b?.monthlyLimit ?? 0;
            final double used = b?.currentSpending ?? 0;
            final double remaining = limit - used;
            final double percent = limit == 0 ? 0 : (used / limit).clamp(0, 1);
            final bool overBudget = limit > 0 && used > limit;
            _budgetController.text = limit > 0 ? limit.toStringAsFixed(2) : '';
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette['card'],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: palette['shadow']!,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Spending',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(used),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                overBudget
                                    ? palette['danger']
                                    : palette['primary'],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Monthly Budget',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(limit),
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: colorScheme.surfaceVariant,
                          color:
                              overBudget
                                  ? palette['danger']
                                  : palette['primary'],
                        ),
                        if (overBudget)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'You are over budget!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Remaining: ' + currency.format(remaining),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                remaining < 0
                                    ? Colors.redAccent
                                    : palette['primary'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          b == null
                              ? 'Set Monthly Budget'
                              : 'Update Monthly Budget',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter a budget amount';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedScale(
                      scale: _isSaving ? 0.96 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: ElevatedButton.icon(
                        icon:
                            b == null
                                ? const Icon(Icons.save)
                                : const Icon(Icons.update),
                        label: Text(
                          b == null ? 'Set Budget' : 'Update Budget',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
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
                                  await _saveBudget(used, b);
                                  if (mounted)
                                    setState(() => _isSaving = false);
                                },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e', style: textTheme.bodyMedium),
        ),
      ),
    );
  }

  Future<void> _saveBudget(double used, Budget? b) async {
    if (_formKey.currentState!.validate()) {
      final newBudget = double.parse(_budgetController.text.trim());
      await ref
          .read(budgetProvider.notifier)
          .upsertBudget(
            b == null
                ? Budget(monthlyLimit: newBudget, currentSpending: used)
                : Budget(
                  id: b.id,
                  monthlyLimit: newBudget,
                  currentSpending: used,
                ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(b == null ? 'Budget set!' : 'Budget updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
