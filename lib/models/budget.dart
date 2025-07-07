class Budget {
  final int? id;
  final double monthlyLimit;
  final double currentSpending;

  Budget({this.id, required this.monthlyLimit, required this.currentSpending});

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      monthlyLimit:
          map['monthlyLimit'] is int
              ? (map['monthlyLimit'] as int).toDouble()
              : map['monthlyLimit'] as double,
      currentSpending:
          map['currentSpending'] is int
              ? (map['currentSpending'] as int).toDouble()
              : map['currentSpending'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthlyLimit': monthlyLimit,
      'currentSpending': currentSpending,
    };
  }
}
 