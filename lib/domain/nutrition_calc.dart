// How it works: a serving is the unit's base numbers times quantity.
// Tadka is also per unit, so it scales with quantity. Medium adds nothing.
// If a fat shift is missing, fat moves by the kcal shift divided by 9.

import 'constants.dart';
import 'models.dart';

/// Nutrition for one base serving, plus optional tadka calorie shifts.
class FoodNutrition {
  const FoodNutrition({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tadkaLightKcal,
    this.tadkaLightFat,
    this.tadkaHeavyKcal,
    this.tadkaHeavyFat,
  });

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// Negative when a lighter tadka has less oil than the base dish.
  final double? tadkaLightKcal;
  final double? tadkaLightFat;

  /// Positive when a heavier tadka has more oil than the base dish.
  final double? tadkaHeavyKcal;
  final double? tadkaHeavyFat;

  bool get hasTadka {
    return tadkaLightKcal != null || tadkaHeavyKcal != null;
  }
}

class FoodCalculator {
  const FoodCalculator();

  Macros forServing({
    required FoodNutrition food,
    double unitFactor = 1.0,
    required double quantity,
    TadkaLevel tadka = TadkaLevel.medium,
  }) {
    if (unitFactor < 0 || quantity < 0) {
      throw ArgumentError('A portion cannot be negative.');
    }
    final double scale = unitFactor * quantity;
    final double tadkaKcal = _tadkaKcal(food, tadka) * quantity;
    final double tadkaFat = _tadkaFat(food, tadka) * quantity;
    return Macros(
      kcal: (food.kcal * scale) + tadkaKcal,
      protein: food.protein * scale,
      carbs: food.carbs * scale,
      fat: (food.fat * scale) + tadkaFat,
    );
  }

  double _tadkaKcal(FoodNutrition food, TadkaLevel tadka) {
    if (!food.hasTadka) {
      return 0;
    }
    switch (tadka) {
      case TadkaLevel.light:
        return food.tadkaLightKcal ?? 0;
      case TadkaLevel.medium:
        return 0;
      case TadkaLevel.heavy:
        return food.tadkaHeavyKcal ?? 0;
    }
  }

  double _tadkaFat(FoodNutrition food, TadkaLevel tadka) {
    if (!food.hasTadka) {
      return 0;
    }
    switch (tadka) {
      case TadkaLevel.light:
        return food.tadkaLightFat ??
            ((food.tadkaLightKcal ?? 0) / BiteConstants.kcalPerGramFat);
      case TadkaLevel.medium:
        return 0;
      case TadkaLevel.heavy:
        return food.tadkaHeavyFat ??
            ((food.tadkaHeavyKcal ?? 0) / BiteConstants.kcalPerGramFat);
    }
  }
}

/// Eaten minus burned. This can be negative if exercise is higher than food.
double netCalories({
  required double eatenKcal,
  required double burnedKcal,
}) {
  return eatenKcal - burnedKcal;
}

/// Target minus net. Positive means kcal still left for the day.
double remainingCalories({
  required double targetKcal,
  required double netKcal,
}) {
  return targetKcal - netKcal;
}
