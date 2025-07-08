// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/savings_goal_provider.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../providers/category_provider.dart';
import '../providers/savings_entry_provider.dart';
import '../main.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider);
    final budget = ref.watch(budgetProvider);
    final goals = ref.watch(savingsGoalProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Custom palette
    final primaryColor = colorScheme.primary;
    const accentGreen = Color(0xFF22C55E);
    const accentOrange = Color(0xFFF59E42);
    const accentPurple = Color(0xFF8B5CF6);
    final cardBg = colorScheme.surface;
    final cardShadow = [
      BoxShadow(
        color: isDark ? Colors.black26 : const Color(0x11000000),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];

    double totalSpending = 0;
    expenses.whenData((list) {
      totalSpending = list.fold(0, (sum, e) => sum + e.amount);
    });

    // ignore: unused_local_variable
    double budgetLimit = 0;
    // ignore: unused_local_variable
    double budgetUsed = 0;
    double budgetRemaining = 0;
    double budgetPercent = 0;
    budget.whenData((b) {
      if (b != null) {
        budgetLimit = b.monthlyLimit;
        budgetUsed = b.currentSpending;
        budgetRemaining = b.monthlyLimit - b.currentSpending;
        budgetPercent = (b.currentSpending /
                (b.monthlyLimit == 0 ? 1 : b.monthlyLimit))
            .clamp(0, 1);
      }
    });

    double savingsTarget = 0;
    double savingsCurrent = 0;
    double savingsProgress = 0;
    goals.whenData((list) {
      if (list.isNotEmpty) {
        savingsTarget = list.first.targetAmount;
        // Calculate savingsCurrent as the sum of all SavingsEntry amounts for the current goal.
        final entriesData = ref.watch(savingsEntryProvider(list.first.id!));
        entriesData.when(
          data: (entries) {
            savingsCurrent = entries.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );
            savingsProgress = (savingsCurrent /
                    (savingsTarget == 0 ? 1 : savingsTarget))
                .clamp(0, 1);
          },
          loading: () {},
          error: (e, _) {},
        );
      }
    });

    // Budget color logic
    Color budgetColor = accentGreen;
    if (budgetPercent > 0.9) {
      budgetColor = Colors.redAccent;
    } else if (budgetPercent > 0.7) {
      budgetColor = accentOrange;
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: const AssetImage('assets/avatar.png'),
              backgroundColor: primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Student 👋',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                Text(
                  'Welcome back!',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: primaryColor),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                backgroundColor: cardBg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder:
                    (context) => Consumer(
                      builder: (context, ref, _) {
                        final themeMode = ref.watch(themeModeProvider);
                        return ListView(
                          shrinkWrap: true,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                              child: Text(
                                'Settings',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Theme', style: textTheme.bodyLarge),
                                  DropdownButton<ThemeMode>(
                                    value: themeMode,
                                    items: const [
                                      DropdownMenuItem(
                                        value: ThemeMode.system,
                                        child: Text('System'),
                                      ),
                                      DropdownMenuItem(
                                        value: ThemeMode.light,
                                        child: Text('Light'),
                                      ),
                                      DropdownMenuItem(
                                        value: ThemeMode.dark,
                                        child: Text('Dark'),
                                      ),
                                    ],
                                    onChanged: (mode) {
                                      if (mode != null) {
                                        ref
                                            .read(themeModeProvider.notifier)
                                            .state = mode;
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Text(
                                'Data Management',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                'Reset All Data',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'This will delete all expenses, budget, and savings goals.',
                              ),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Reset All Data?'),
                                        content: const Text(
                                          'Are you sure you want to delete all expenses, budget, and savings goals? This cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  await BudgetService().resetAll();
                                  await CategoryService()
                                      .insertDefaultCategories();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ref
                                        .read(expenseProvider.notifier)
                                        .fetchExpenses();
                                    ref
                                        .read(budgetProvider.notifier)
                                        .fetchBudget();
                                    ref
                                        .read(savingsGoalProvider.notifier)
                                        .fetchGoals();
                                    ref
                                        .read(categoryProvider.notifier)
                                        .fetchCategories();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All data reset!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            // Total Spending Card
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder:
                  (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: expenses.when(
                    data:
                        (list) => Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.trending_up,
                                color: primaryColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Spending',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currency.format(totalSpending),
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Trend indicator (mock)
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: accentOrange,
                                  size: 20,
                                ),
                                Text(
                                  '2%',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: accentOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, _) =>
                            Text('Error: $e', style: textTheme.bodyMedium),
                  ),
                ),
              ),
            ),
            // Budget Card
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder:
                  (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: budget.when(
                    data:
                        (b) =>
                            b == null
                                ? const Text(
                                  'No budget set',
                                  style: TextStyle(color: Colors.black54),
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: budgetColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.account_balance_wallet,
                                            color: budgetColor,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Budget Remaining',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currency.format(
                                                  budgetRemaining,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: budgetColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${(budgetPercent * 100).toStringAsFixed(0)}% used',
                                          style: TextStyle(
                                            color: budgetColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                      value: budgetPercent,
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(8),
                                      backgroundColor: Colors.grey[200],
                                      color: budgetColor,
                                    ),
                                  ],
                                ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ),
            ),
            // Savings Goal Card
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder:
                  (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: goals.when(
                    data:
                        (list) =>
                            list.isEmpty
                                ? const Text(
                                  'No savings goal set',
                                  style: TextStyle(color: Colors.black54),
                                )
                                : Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: CircularProgressIndicator(
                                            value: savingsProgress,
                                            strokeWidth: 7,
                                            backgroundColor: accentPurple
                                                .withOpacity(0.15),
                                            color: accentPurple,
                                          ),
                                        ),
                                        Text(
                                          '${(savingsProgress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accentPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Savings Goal',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${currency.format(savingsCurrent)} / ${currency.format(savingsTarget)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: accentPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Keep going! 🎯',
                                            style: TextStyle(
                                              color: accentPurple.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ),
            ),
            // Recent Transactions Section
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              builder:
                  (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: expenses.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return const Text(
                          'No recent transactions.',
                          style: TextStyle(color: Colors.black54),
                        );
                      }
                      final recent = list.take(3).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...recent.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: colorScheme.primary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e.title,
                                      style: textTheme.bodyLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currency.format(e.amount),
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, _) =>
                            Text('Error: $e', style: textTheme.bodyMedium),
                  ),
                ),
              ),
            ),
            // Tip of the Day Card
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder:
                  (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tip of the Day',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track your expenses daily to avoid surprises at the end of the month! Small habits make a big difference.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSecondaryContainer
                                    .withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
