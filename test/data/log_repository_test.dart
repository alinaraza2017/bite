import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/models/food_unit.dart';
import 'package:bite/data/repositories/food_repository.dart';
import 'package:bite/data/repositories/log_repository.dart';
import 'package:bite/domain/models.dart';

import 'test_database.dart';

void main() {
  test('a log stores the portion and can be undone', () async {
    final TestDatabase db = await openTestDatabase();
    final FoodRepository foods = FoodRepository(db.database);
    final int foodId = await foods.addCustomFood(
      name: 'Roti',
      category: 'Roti',
      unit: const FoodUnitInput(
        label: '1 roti',
        grams: 40,
        calories: 120,
        protein: 3,
        carbs: 24,
        fat: 1,
      ),
    );
    final food = (await foods.foodById(foodId))!;
    final unit = (await foods.unitsFor(foodId)).single;
    final LogRepository logs = LogRepository(db.database);

    final saved = await logs.addLog(
      date: '2026-10-27',
      meal: 'dinner',
      food: food,
      unit: unit,
      quantity: 2,
      tadka: TadkaLevel.medium,
    );
    expect(saved.calories, 240);
    expect(saved.foodName, 'Roti');

    final removed = await logs.deleteLog(saved.id);
    expect(await logs.foodsForDate('2026-10-27'), isEmpty);
    await logs.restoreLog(removed!);
    expect((await logs.foodsForDate('2026-10-27')).single.calories, 240);
    await db.close();
  });
}
