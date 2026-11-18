import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/repositories/progress_repository.dart';
import 'package:bite/domain/progress_calc.dart';
import 'package:bite/features/progress/sample_progress_data.dart';

import 'test_database.dart';

void main() {
  test('load fills the window and clear leaves real rows', () async {
    final TestDatabase db = await openTestDatabase();
    addTearDown(db.close);
    final int foodId = await db.database.insert('foods', <String, Object?>{
      'name': 'Roti',
      'category': 'Bread',
      'created_at': 'test',
    });
    final int unitId = await db.database.insert('serving_units', <String, Object?>{
      'food_id': foodId,
      'label': 'piece',
      'grams': 40,
      'calories': 120,
      'protein': 3,
      'carbs': 20,
      'fat': 1,
    });
    await db.database.insert('food_logs', <String, Object?>{
      'date': '2026-10-26',
      'meal': 'lunch',
      'food_id': foodId,
      'unit_id': unitId,
      'quantity': 1,
      'calories': 1890,
      'protein': 80,
      'carbs': 200,
      'fat': 50,
      'created_at': 'real-user',
    });
    await db.database.insert('weight_logs', <String, Object?>{
      'weight_kg': 70,
      'logged_at': '2026-10-22',
    });

    final ProgressRepository repository = ProgressRepository(db.database);
    final report = await repository.load(
      today: DateTime(2026, 10, 28),
      dayCount: 7,
      calorieTarget: 2100,
      proteinTarget: 100,
    );
    expect(report.days, hasLength(7));
    expect(report.loggedDays, 1);
    expect(report.averageCalories, 1890);
    expect(report.daysOnTarget, 1);
    expect(report.weights, hasLength(1));

    final SampleProgressData sample = SampleProgressData(db.database);
    await sample.generate();
    await sample.clear();

    final List<Map<String, Object?>> foods = await db.database.query('food_logs');
    expect(foods, hasLength(1));
    expect(foods.single['created_at'], 'real-user');
    final List<Map<String, Object?>> weights = await db.database.query('weight_logs');
    expect(weights, hasLength(1));
    expect(weights.single['logged_at'], '2026-10-22');
    expect(
      await db.database.query(
        'workout_sessions',
        where: 'name = ?',
        whereArgs: <Object>[ProgressRepository.sampleSessionName],
      ),
      isEmpty,
    );
  });

  test('sample rows use the date key the food log uses', () async {
    expect(progressDayKey(DateTime(2026, 10, 28, 15)), '2026-10-28');
  });
}
