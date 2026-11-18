/// One household measure. The numbers are for a single unit at Medium tadka.
class FoodUnit {
  const FoodUnit({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
    required this.isDefault,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int id;
  final int foodId;
  final String label;
  final double grams;
  final bool isDefault;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory FoodUnit.fromMap(Map<String, Object?> map) {
    return FoodUnit(
      id: (map['id'] as num).toInt(),
      foodId: (map['food_id'] as num).toInt(),
      label: map['label'] as String,
      grams: (map['grams'] as num).toDouble(),
      isDefault: (map['is_default'] as num).toInt() == 1,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }
}

/// A unit that does not have a database id yet. Used when saving a custom food.
class FoodUnitInput {
  const FoodUnitInput({
    required this.label,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isDefault = true,
  });

  final String label;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isDefault;
}
