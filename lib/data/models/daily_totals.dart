/// Sum of the snapshot columns for one day.
/// Domain has no Macros.sum, so this is only the added-up log rows.
class DailyTotals {
  const DailyTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  static const DailyTotals zero = DailyTotals(
    kcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );

  factory DailyTotals.fromMap(Map<String, Object?> map) {
    return DailyTotals(
      kcal: (map['kcal'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }
}
