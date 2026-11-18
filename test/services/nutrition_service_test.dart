import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/models.dart';
import 'package:bite/services/nutrition_service.dart';

void main() {
  test('Chicken Karahi medium is 320 kcal', () {
    final PortionNumbers numbers = estimatePortion(
      unitCalories: 320,
      unitProtein: 25,
      unitCarbs: 8,
      unitFat: 21,
      quantity: 1,
      hasTadka: true,
      tadkaLightKcal: -45,
      tadkaLightFat: -5,
      tadkaHeavyKcal: 70,
      tadkaHeavyFat: 7.7778,
    );
    expect(numbers.calories, 320);
    expect(numbers.protein, 25);
    expect(numbers.carbs, 8);
    expect(numbers.fat, 21);
  });

  test('Daal light one pyali is 150 kcal', () {
    final PortionNumbers numbers = estimatePortion(
      unitCalories: 190,
      unitProtein: 12,
      unitCarbs: 28,
      unitFat: 4,
      quantity: 1,
      hasTadka: true,
      tadka: TadkaLevel.light,
      tadkaLightKcal: -40,
      tadkaLightFat: -4.4444,
      tadkaHeavyKcal: 60,
      tadkaHeavyFat: 6.6667,
    );
    expect(numbers.calories, 150);
  });

  test('quantity scales the whole portion', () {
    final PortionNumbers numbers = estimatePortion(
      unitCalories: 320,
      unitProtein: 25,
      unitCarbs: 8,
      unitFat: 21,
      quantity: 2,
      hasTadka: true,
      tadka: TadkaLevel.light,
      tadkaLightKcal: -45,
      tadkaLightFat: -5,
    );
    expect(numbers.calories, 550);
    expect(numbers.protein, 50);
    expect(numbers.fat, 32);
  });
}
