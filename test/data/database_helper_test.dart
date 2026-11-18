import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'test_database.dart';

void main() {
  late TestDatabase testDb;

  setUp(() async {
    testDb = await openTestDatabase();
  });

  tearDown(() async {
    await testDb.close();
  });

  test('spec indexes exist', () async {
    final List<Map<String, Object?>> rows = await testDb.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    final Set<Object?> names = rows.map((Map<String, Object?> row) {
      return row['name'];
    }).toSet();
    expect(
      names,
      containsAll([
        'idx_food_logs_date',
        'idx_foods_name',
        'idx_foods_category',
        'idx_workout_sets_exercise',
        'idx_workout_sessions_date',
      ]),
    );
  });

  test('deleting a food removes its units', () async {
    final int foodId = await testDb.database.insert('foods', {
      'name': 'Roti',
      'category': 'Roti',
      'is_custom': 0,
      'has_tadka': 0,
      'created_at': '2026-10-27',
    });
    await testDb.database.insert('serving_units', {
      'food_id': foodId,
      'label': 'roti',
      'grams': 40,
      'is_default': 1,
      'calories': 120,
      'protein': 3,
      'carbs': 24,
      'fat': 1,
    });

    await testDb.database.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );

    final List<Map<String, Object?>> units = await testDb.database.query(
      'serving_units',
    );
    expect(units, isEmpty);
  });

  test('a unit cannot point at a missing food', () async {
    expect(
      () => testDb.database.insert('serving_units', {
        'food_id': 999,
        'label': 'roti',
        'grams': 40,
        'is_default': 1,
        'calories': 120,
        'protein': 3,
        'carbs': 24,
        'fat': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
