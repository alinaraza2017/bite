import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/models/food_unit.dart';
import 'package:bite/data/repositories/food_repository.dart';

import 'test_database.dart';

void main() {
  test('custom food can be found by name and category', () async {
    final TestDatabase db = await openTestDatabase();
    final FoodRepository foods = FoodRepository(db.database);
    final int id = await foods.addCustomFood(
      name: 'Home plate',
      category: 'Main meals',
      unit: const FoodUnitInput(
        label: '1 plate',
        grams: 100,
        calories: 200,
        protein: 10,
        carbs: 20,
        fat: 5,
      ),
    );

    expect(await foods.customCount(), 1);
    final found = await foods.searchFoods('Home', category: 'Main meals');
    expect(found.single.id, id);
    expect(found.single.defaultCalories, 200);
    expect(found.single.defaultUnitLabel, '1 plate');
    expect((await foods.unitsFor(id)).single.protein, 10);
    await db.close();
  });
}
