class SavingsEntry {
  final int? id;
  final double amount;
  final DateTime date;
  final int goalId;

  SavingsEntry({
    this.id,
    required this.amount,
    required this.date,
    required this.goalId,
  });

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    return SavingsEntry(
      id: map['id'] as int?,
      amount:
          map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      goalId: map['goalId'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'goalId': goalId,
    };
  }
}
