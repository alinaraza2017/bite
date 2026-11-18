import '../domain/models.dart';
import '../domain/nutrition_calc.dart';

// How it works: the unit row already stores Medium tadka.
// Light and heavy add their own kcal and fat, once per unit.
// The screen shows whole kcal and whole grams.

class PortionNumbers {
  const PortionNumbers({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
}

/// Calories and macros for one logged portion. This is an estimate.
PortionNumbers estimatePortion({
  required double unitCalories,
  required double unitProtein,
  required double unitCarbs,
  required double unitFat,
  required double quantity,
  required bool hasTadka,
  TadkaLevel tadka = TadkaLevel.medium,
  double tadkaLightKcal = 0,
  double tadkaLightFat = 0,
  double tadkaHeavyKcal = 0,
  double tadkaHeavyFat = 0,
}) {
  final Macros raw = const FoodCalculator().forServing(
    food: FoodNutrition(
      kcal: unitCalories,
      protein: unitProtein,
      carbs: unitCarbs,
      fat: unitFat,
      tadkaLightKcal: hasTadka ? tadkaLightKcal : null,
      tadkaLightFat: hasTadka ? tadkaLightFat : null,
      tadkaHeavyKcal: hasTadka ? tadkaHeavyKcal : null,
      tadkaHeavyFat: hasTadka ? tadkaHeavyFat : null,
    ),
    quantity: quantity,
    tadka: tadka,
  );
  return PortionNumbers(
    calories: raw.kcal.round(),
    protein: raw.protein.round(),
    carbs: raw.carbs.round(),
    fat: raw.fat.round(),
  );
}
