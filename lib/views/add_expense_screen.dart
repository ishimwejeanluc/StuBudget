// ignore_for_file: deprecated_member_use, unused_local_variable, curly_braces_in_flow_control_structures, duplicate_ignore, use_build_context_synchronously, await_only_futures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    // Check if budget is set
    final budgetAsync = ref.read(budgetProvider);
    final budget = budgetAsync.asData?.value;
    if (budget == null || budget.monthlyLimit <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please set your monthly budget before adding expenses.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate() || _selectedCategoryId == null)
      return;
    final categories = ref
        .read(categoryProvider)
        .maybeWhen(data: (list) => list, orElse: () => []);
    final category = categories.firstWhere((c) => c.id == _selectedCategoryId);
    final expense = Expense(
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      category: category.name,
      note:
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
    );
    await ref.read(expenseProvider.notifier).addExpense(expense);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: colorScheme.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'New Expense',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Enter a title'
                                  : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter an amount';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    categories.when(
                      data:
                          (list) => DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            items:
                                list
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Row(
                                          children: [
                                            Icon(c.icon, color: c.color),
                                            const SizedBox(width: 8),
                                            Text(
                                              c.name,
                                              style: textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setState(() => _selectedCategoryId = v),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              filled: true,
                              fillColor: colorScheme.surfaceVariant,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                          ),
                      loading: () => const CircularProgressIndicator(),
                      error:
                          (e, _) =>
                              Text('Error: $e', style: textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          filled: true,
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat.yMMMd().format(_selectedDate)),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        filled: true,
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedScale(
                        scale: _isSaving ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Save Expense',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                                    await _saveExpense();
                                    if (mounted)
                                      setState(() => _isSaving = false);
                                  },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) async {
          if (index == 1) return; // Already on Add
          // Use a post-frame callback for smoother transition
          Future.delayed(Duration.zero, () {
            Navigator.of(context).pop(index);
          });
        },
        height: 70,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor: colorScheme.primary.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: colorScheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: colorScheme.primary),
            label: 'Add',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: colorScheme.primary,
            ),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings, color: colorScheme.primary),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: colorScheme.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
