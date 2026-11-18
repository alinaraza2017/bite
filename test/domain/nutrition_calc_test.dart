import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/models.dart';
import 'package:bite/domain/nutrition_calc.dart';

void main() {
  const FoodCalculator calculator = FoodCalculator();
  const FoodNutrition karahi = FoodNutrition(
    kcal: 320,
    protein: 25,
    carbs: 8,
    fat: 21,
    tadkaLightKcal: -45,
    tadkaHeavyKcal: 70,
  );
  const FoodNutrition roti = FoodNutrition(
    kcal: 112,
    protein: 3.6,
    carbs: 20.8,
    fat: 1.6,
  );

  test('medium chicken karahi uses the base serving', () {
    final Macros one = calculator.forServing(food: karahi, quantity: 1);
    expect(one.kcal, 320);
    expect(one.protein, 25);
    expect(one.carbs, 8);
    expect(one.fat, 21);

    final Macros two = calculator.forServing(food: karahi, quantity: 2);
    expect(two.kcal, 640);
    expect(two.protein, 50);
    expect(two.carbs, 16);
    expect(two.fat, 42);
  });

  test('unit factor scales the base and not a missing adjustment', () {
    final Macros half = calculator.forServing(
      food: karahi,
      quantity: 1,
      unitFactor: 0.5,
    );
    expect(half.kcal, 160);
    expect(half.protein, 12.5);
    expect(half.carbs, 4);
    expect(half.fat, 10.5);
  });

  test('light and heavy tadka scale with quantity', () {
    final Macros light = calculator.forServing(
      food: karahi,
      quantity: 1,
      tadka: TadkaLevel.light,
    );
    expect(light.kcal, 275);
    expect(light.fat, 16);
    expect(light.protein, 25);
    expect(light.carbs, 8);

    final Macros heavy = calculator.forServing(
      food: karahi,
      quantity: 1,
      tadka: TadkaLevel.heavy,
    );
    expect(heavy.kcal, 390);
    expect(heavy.fat, closeTo(21 + (70 / 9), 0.001));

    final Macros twoLight = calculator.forServing(
      food: karahi,
      quantity: 2,
      tadka: TadkaLevel.light,
    );
    expect(twoLight.kcal, 550);
    expect(twoLight.fat, closeTo(32, 0.001));
  });

  test('a food with no tadka ignores a heavy choice', () {
    final Macros heavyRoti = calculator.forServing(
      food: roti,
      quantity: 1,
      tadka: TadkaLevel.heavy,
    );
    expect(heavyRoti.kcal, 112);
    expect(heavyRoti.fat, 1.6);
  });

  test('a tiny light portion scales and is not clamped', () {
    final Macros tiny = calculator.forServing(
      food: karahi,
      quantity: 0.01,
      tadka: TadkaLevel.light,
    );
    expect(tiny.kcal, closeTo(2.75, 0.001));
    expect(tiny.fat, closeTo(0.16, 0.001));
  });

  test('a negative portion throws', () {
    expect(
      () => calculator.forServing(food: karahi, quantity: -1),
      throwsArgumentError,
    );
    expect(
      () => calculator.forServing(food: karahi, quantity: 1, unitFactor: -1),
      throwsArgumentError,
    );
  });

  test('Macros.sum adds items and an empty list is zero', () {
    final Macros total = Macros.sum([
      const Macros(kcal: 100, protein: 10, carbs: 8, fat: 4),
      const Macros(kcal: 50, protein: 2, carbs: 3, fat: 1),
    ]);
    expect(total.kcal, 150);
    expect(total.protein, 12);
    expect(total.carbs, 11);
    expect(total.fat, 5);
    expect(Macros.sum(const <Macros>[]).kcal, 0);
    expect(Macros.sum(const <Macros>[]).protein, 0);
  });
}
