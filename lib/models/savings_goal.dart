class SavingsGoal {
  final int? id;
  final double targetAmount;
  final DateTime deadline;
  // The total saved is now calculated from SavingsEntry

  SavingsGoal({this.id, required this.targetAmount, required this.deadline});

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      targetAmount:
          map['targetAmount'] is int
              ? (map['targetAmount'] as int).toDouble()
              : map['targetAmount'] as double,
      deadline: DateTime.parse(map['deadline'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'targetAmount': targetAmount,
      'deadline': deadline.toIso8601String(),
    };
  }
}
