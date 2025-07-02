import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingGoalSummary extends StatelessWidget {
  final double target;
  final double saved;
  final DateTime deadline;

  const SavingGoalSummary({
    super.key,
    required this.target,
    required this.saved,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');
    final remaining = (target - saved).clamp(0, double.infinity);
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'Target', value: currency.format(target)),
            _SummaryRow(label: 'Saved', value: currency.format(saved)),
            _SummaryRow(label: 'Remaining', value: currency.format(remaining)),
            _SummaryRow(
              label: 'Deadline',
              value: DateFormat.yMMMd().format(deadline),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
