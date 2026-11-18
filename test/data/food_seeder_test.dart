import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bite/data/models/food_unit.dart';
import 'package:bite/data/repositories/food_repository.dart';
import 'package:bite/data/seed/food_seeder.dart';
import 'package:bite/features/food/food_screen.dart';

import 'test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chips follow the JSON order and start with All', () {
    final List<String> chips = foodChips(
      <String>['Snacks', 'Roti & Bread', 'Extra'],
      jsonEncode(<String>['Roti & Bread', 'Snacks']),
    );
    expect(chips, <String>['All', 'Roti & Bread', 'Snacks', 'Extra']);
  });

  test('merge keeps old foods, logs, and adds the new catalog', () async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TestDatabase testDb = await openTestDatabase();
    final List<String> previous = (jsonDecode(
      File('test/data/previous_catalog_names.json').readAsStringSync(),
    ) as List<dynamic>)
        .cast<String>();

    final Map<String, int> before = await _counts(testDb.database);
    expect(before.values.fold<int>(0, (int sum, int count) => sum + count), 0);

    int? karahiId;
    for (final String name in previous) {
      final bool karahi = name == 'Chicken Karahi';
      final int foodId = await testDb.database.insert('foods', <String, Object?>{
        'name': name,
        'category': karahi ? 'Main meals' : 'Old',
        'is_custom': 0,
        'has_tadka': karahi ? 1 : 0,
        'is_favorite': karahi ? 1 : 0,
        'tadka_light_kcal': karahi ? -45 : null,
        'created_at': '2026-01-01T00:00:00.000',
      });
      final int unitId = await testDb.database.insert('serving_units', <String, Object?>{
        'food_id': foodId,
        'label': karahi ? '1 karchi' : '1 piece',
        'grams': 100,
        'is_default': 1,
        'calories': karahi ? 320 : 100,
        'protein': karahi ? 25 : 1,
        'carbs': karahi ? 8 : 1,
        'fat': karahi ? 21 : 1,
      });
      if (karahi) {
        karahiId = foodId;
        await testDb.database.insert('food_logs', <String, Object?>{
          'date': '2026-01-01',
          'meal': 'lunch',
          'food_id': foodId,
          'unit_id': unitId,
          'quantity': 1,
          'tadka': 'medium',
          'calories': 320,
          'protein': 25,
          'carbs': 8,
          'fat': 21,
          'created_at': '2026-01-01T00:00:00.000',
        });
      }
    }
    final int customId = await FoodRepository(testDb.database).addCustomFood(
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

    final Map<String, int> loadedBefore = await _counts(testDb.database);
    // ignore: avoid_print
    print('BEFORE ${loadedBefore.entries.map((e) => '${e.key}:${e.value}').join(', ')}');

    final FoodSeeder seeder = FoodSeeder();
    await seeder.seed(testDb.database, preferences);
    await seeder.seed(testDb.database, preferences);

    final Map<String, int> after = await _counts(testDb.database);
    // ignore: avoid_print
    print('AFTER ${after.entries.map((e) => '${e.key}:${e.value}').join(', ')}');

    for (final String name in previous) {
      final int? still = Sqflite.firstIntValue(
        await testDb.database.rawQuery(
          'SELECT COUNT(*) FROM foods WHERE name = ? AND is_custom = 0',
          <Object>[name],
        ),
      );
      expect(still, 1, reason: name);
    }

    final int? karahiRows = Sqflite.firstIntValue(
      await testDb.database.rawQuery(
        "SELECT COUNT(*) FROM foods WHERE LOWER(name) = 'chicken karahi'",
      ),
    );
    expect(karahiRows, 1);

    final List<Map<String, Object?>> kept = await testDb.database.query(
      'serving_units',
      where: "food_id = ? AND label = '1 karchi'",
      whereArgs: <Object>[karahiId!],
    );
    expect(kept.single['calories'], 320);
    final List<Map<String, Object?>> karahiRow = await testDb.database.query(
      'foods',
      where: 'id = ?',
      whereArgs: <Object>[karahiId],
    );
    expect(karahiRow.single['is_favorite'], 1);
    expect(karahiRow.single['has_tadka'], 1);
    expect((karahiRow.single['aliases'] as String).toLowerCase(), contains('karahi'));

    final int? logs = Sqflite.firstIntValue(
      await testDb.database.rawQuery('SELECT COUNT(*) FROM food_logs'),
    );
    expect(logs, 1);
    expect(await FoodRepository(testDb.database).customCount(), 1);
    final custom = await FoodRepository(testDb.database).foodById(customId);
    expect(custom!.name, 'Home plate');

    final FoodRepository repository = FoodRepository(testDb.database);
    expect((await repository.searchFoods('karahi')).first.name, 'Chicken Karahi');
    expect((await repository.searchFoods('qeema')).first.name, 'Keema');
    expect((await repository.searchFoods('nehari')).first.name, 'Nihari');
    expect(await repository.searchFoods('chai'), isNotEmpty);
    expect((await repository.searchFoods('banana')).first.name, 'Banana');
    expect(await repository.searchFoods('pizza'), isNotEmpty);
    expect(await repository.searchFoods('protein'), isNotEmpty);
    expect(
      (await repository.searchFoods('chapati')).map((food) => food.name),
      contains('Chapati'),
    );
    expect(
      (await repository.searchFoods('karahi')).length,
      lessThanOrEqualTo(50),
    );

    final int? catalog = Sqflite.firstIntValue(
      await testDb.database.rawQuery(
        'SELECT COUNT(*) FROM foods WHERE is_custom = 0',
      ),
    );
    expect(catalog, greaterThan(previous.length));
    await testDb.close();
  });
}

Future<Map<String, int>> _counts(Database database) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    '''
    SELECT category, COUNT(*) AS total
    FROM foods
    WHERE is_custom = 0
    GROUP BY category
    ORDER BY category
    ''',
  );
  return <String, int>{
    for (final Map<String, Object?> row in rows)
      row['category'] as String: (row['total'] as num).toInt(),
  };
}
