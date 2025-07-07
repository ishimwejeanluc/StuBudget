// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'budget_screen.dart';
import 'add_expense_screen.dart';
import 'package:studentbudgetv1/views/savings_goal_screen.dart';
import 'reports_screen.dart';
// Placeholder imports for future screens
// import 'goals_screen.dart';
// import 'reports_screen.dart';

class MainNavShell extends ConsumerStatefulWidget {
  const MainNavShell({super.key});

  @override
  ConsumerState<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends ConsumerState<MainNavShell> {
  int _selectedIndex = 0;

  void _navigateWithFade(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onResult,
  }) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (onResult != null) onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const AddExpenseScreen(),
      const BudgetScreen(),
      const SavingGoalScreen(),
      const ReportsScreen(),
      const Center(
        child: Text('Goals (Coming Soon)', style: TextStyle(fontSize: 18)),
      ),
      const Center(
        child: Text('Reports (Coming Soon)', style: TextStyle(fontSize: 18)),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index:
            _selectedIndex == 1
                ? 0
                : _selectedIndex, // Don't show Add tab as main
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          if (index == 1) {
            _navigateWithFade(
              context,
              const AddExpenseScreen(),
              onResult: (result) {
                if (result != null && result != 1) {
                  setState(() => _selectedIndex = result);
                }
              },
            );
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        height: 70,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            selectedIcon: Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.savings_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            selectedIcon: Icon(
              Icons.savings,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.pie_chart_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            selectedIcon: Icon(
              Icons.pie_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
