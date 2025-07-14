// ignore_for_file: sized_box_for_whitespace, use_super_parameters, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/savings_entry_provider.dart';
import '../models/savings_goal.dart';
import '../models/savings_entry.dart';

const kCardRadius = 20.0;

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late String _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat.MMMM().format(now);
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      12,
      (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
    );
    final years = List.generate(3, (i) => DateTime.now().year - i);

    return Theme(
      data: Theme.of(context),
      child: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _FilterCard(
                      months: months,
                      years: years,
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                      onMonthChanged:
                          (m) => setState(() => _selectedMonth = m!),
                      onYearChanged: (y) => setState(() => _selectedYear = y!),
                    ),
                  ),
                ),
              ),
            ],
        body: _ReportsBody(
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final List<String> months;
  final List<int> years;
  final String selectedMonth;
  final int selectedYear;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const _FilterCard({
    required this.months,
    required this.years,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMonth,
                  items:
                      months
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onMonthChanged,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 22,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(width: 2),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              const SizedBox(width: 2),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedYear,
                  items:
                      years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(
                                y.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onYearChanged,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 22,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  alignment: Alignment.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  final String selectedMonth;
  final int selectedYear;
  const _ReportsBody({required this.selectedMonth, required this.selectedYear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final goalsAsync = ref.watch(savingsGoalProvider);
    final months = List.generate(
      12,
      (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
    );
    final monthNum = months.indexOf(selectedMonth) + 1;
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        return goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (goals) {
            // Filter expenses by month/year
            final filteredExpenses =
                expenses
                    .where(
                      (e) =>
                          e.date.month == monthNum &&
                          e.date.year == selectedYear,
                    )
                    .toList();
            // Top categories
            final Map<String, double> categoryTotals = {};
            for (final e in filteredExpenses) {
              categoryTotals[e.category] =
                  (categoryTotals[e.category] ?? 0) + e.amount;
            }
            final topCategories =
                categoryTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
            final topCategoriesData = topCategories.take(5).toList();
            // Savings goals and entries
            final List<SavingsGoal> sortedGoals = List.from(goals)
              ..sort((a, b) => a.deadline.compareTo(b.deadline));
            final currentGoal =
                sortedGoals.isNotEmpty ? sortedGoals.first : null;
            final entriesAsync =
                currentGoal != null
                    ? ref.watch(savingsEntryProvider(currentGoal.id!))
                    : const AsyncValue<List<SavingsEntry>>.data([]);
            return entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                // Filter savings entries by month/year
                final filteredEntries =
                    entries
                        .where(
                          (e) =>
                              e.date.month == monthNum &&
                              e.date.year == selectedYear,
                        )
                        .toList();
                // Saving rate over time (cumulative)
                final daysInMonth = DateUtils.getDaysInMonth(
                  selectedYear,
                  monthNum,
                );
                List<double> savingsOverTime = List.filled(daysInMonth, 0);
                for (final entry in filteredEntries) {
                  final day = entry.date.day - 1;
                  for (int i = day; i < daysInMonth; i++) {
                    savingsOverTime[i] += entry.amount;
                  }
                }
                // Goal progress
                final goalTarget = currentGoal?.targetAmount ?? 1;
                final goalSaved = filteredEntries.fold(
                  0.0,
                  (sum, e) => sum + e.amount,
                );
                final percentSaved = (goalSaved / goalTarget).clamp(0.0, 1.0);
                // Insights
                final spent = filteredExpenses.fold(
                  0.0,
                  (sum, e) => sum + e.amount,
                );
                final bestDay =
                    filteredEntries.isNotEmpty
                        ? DateFormat.MMMd().format(
                          filteredEntries
                              .reduce((a, b) => a.amount > b.amount ? a : b)
                              .date,
                        )
                        : '-';
                return ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    // Insight Tiles
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            builder:
                                (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                            child: _InfoTile(
                              icon: '💸',
                              label: 'Spent',
                              value: currency.format(spent),
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            builder:
                                (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                            child: _InfoTile(
                              icon: '✅',
                              label: 'Saved',
                              value: currency.format(goalSaved),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 700),
                            builder:
                                (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                            child: _InfoTile(
                              icon: '🔥',
                              label: 'Best Day',
                              value: bestDay,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Goal Progress Gauge
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kCardRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: GoalProgressGauge(
                              percent: percentSaved,
                              saved: goalSaved,
                              target: goalTarget,
                              currency: currency,
                              key: ValueKey(percentSaved),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Savings Trend Chart
                    _SectionCard(
                      icon: Icons.show_chart,
                      label: 'Savings Trend',
                      child: AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 600),
                        child: AspectRatio(
                          aspectRatio: 1.7,
                          child: SavingRateChart(
                            savingsOverTime: savingsOverTime,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Top Categories Chart
                    _SectionCard(
                      icon: Icons.bar_chart,
                      label: 'Top Expenses',
                      child: AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 600),
                        child: AspectRatio(
                          aspectRatio: 1.3,
                          child: TopCategoriesChart(
                            categories: topCategoriesData,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class SavingRateChart extends StatelessWidget {
  final List<double> savingsOverTime;
  const SavingRateChart({Key? key, required this.savingsOverTime})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = List.generate(
      savingsOverTime.length,
      (i) => FlSpot(i.toDouble() + 1, savingsOverTime[i]),
    );
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 2000, // Show every 2K, adjust as needed
              getTitlesWidget: (value, meta) {
                if (value == 0)
                  // ignore: curly_braces_in_flow_control_structures
                  return const Text('0', style: TextStyle(fontSize: 10));
                if (value % 2000 == 0) {
                  return Text(
                    '${(value ~/ 1000)}K',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval:
                  (savingsOverTime.length / 5)
                      .ceilToDouble(), // Show 5 labels max
              getTitlesWidget: (value, meta) {
                if (value == 1 || value == savingsOverTime.length) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                if (value % ((savingsOverTime.length / 5).ceilToDouble()) ==
                    0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class TopCategoriesChart extends StatelessWidget {
  final List<MapEntry<String, double>> categories;
  const TopCategoriesChart({Key? key, required this.categories})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Colors.red,
      Colors.grey,
    ];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(categories.length, (i) {
          final cat = categories[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cat.value,
                color: colors[i % colors.length],
                width: 24,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10000, // Show every 10K, adjust as needed
              getTitlesWidget: (value, meta) {
                if (value == 0)
                  // ignore: curly_braces_in_flow_control_structures
                  return const Text('0', style: TextStyle(fontSize: 10));
                if (value % 10000 == 0) {
                  return Text(
                    '${(value ~/ 1000)}K',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval:
                  (categories.length / 5).ceilToDouble(), // Show 5 labels max
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= categories.length) return Container();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    categories[i].key,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
      ),
    );
  }
}

class GoalProgressGauge extends StatelessWidget {
  final double percent;
  final double saved;
  final double target;
  final NumberFormat currency;
  const GoalProgressGauge({
    Key? key,
    required this.percent,
    required this.saved,
    required this.target,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 800),
                builder:
                    (context, value, child) => CustomPaint(
                      painter: _RadialGaugePainter(value, primary, secondary),
                      child: const SizedBox.expand(),
                    ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              'Target: ',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            Text(
              currency.format(target),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              'Saved: ',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            Text(
              currency.format(saved),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color secondaryColor;
  _RadialGaugePainter(this.percent, this.color, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -3.14 / 2;
    final sweepAngle = 2 * 3.14 * percent;
    final paintBg =
        Paint()
          ..color = Colors.grey[200]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12;
    final paintFg =
        Paint()
          ..shader = LinearGradient(
            colors: [color, secondaryColor],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 12;
    canvas.drawArc(rect.deflate(8), 0, 2 * 3.14, false, paintBg);
    canvas.drawArc(rect.deflate(8), startAngle, sweepAngle, false, paintFg);
    // Shadow
    if (percent > 0) {
      final shadowPaint =
          Paint()
            ..color = color.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16;
      canvas.drawArc(
        rect.deflate(8),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.secondaryColor != secondaryColor;
}
