/// One saved food row, with the name and unit copied for the list.
class LoggedFood {
  const LoggedFood({
    required this.id,
    required this.date,
    required this.meal,
    required this.foodId,
    required this.unitId,
    required this.quantity,
    required this.tadka,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.foodName,
    required this.unitLabel,
    required this.hasTadka,
    required this.category,
    this.emoji = '🍽️',
  });

  final int id;
  final String date;
  final String meal;
  final int foodId;
  final int unitId;
  final double quantity;
  final String? tadka;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String foodName;
  final String unitLabel;
  final bool hasTadka;
  final String category;
  final String emoji;

  factory LoggedFood.fromMap(Map<String, Object?> map) {
    final Object? tadka = map['tadka'];
    return LoggedFood(
      id: (map['id'] as num).toInt(),
      date: map['date'] as String,
      meal: map['meal'] as String,
      foodId: (map['food_id'] as num).toInt(),
      unitId: (map['unit_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toDouble(),
      tadka: tadka == null ? null : tadka as String,
      calories: (map['calories'] as num).round(),
      protein: (map['protein'] as num).round(),
      carbs: (map['carbs'] as num).round(),
      fat: (map['fat'] as num).round(),
      foodName: map['food_name'] as String,
      unitLabel: map['unit_label'] as String,
      hasTadka: (map['has_tadka'] as num).toInt() == 1,
      category: map['category'] as String,
      emoji: (map['food_emoji'] as String?) ?? '🍽️',
    );
  }
}
