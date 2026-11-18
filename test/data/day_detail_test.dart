import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/repositories/progress_repository.dart';

import 'test_database.dart';

void main() {
  test('getDayDetail is empty, mixed, and stays on the calendar day', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);
    final int foodId = await db.database.insert('foods', <String, Object?>{
      'name': 'Daal',
      'category': 'Daal',
      'emoji': '🥣',
      'created_at': 'test',
    });
    final int unitId = await db.database.insert('serving_units', <String, Object?>{
      'food_id': foodId,
      'label': 'pyali',
      'grams': 200,
      'calories': 180,
      'protein': 10,
      'carbs': 20,
      'fat': 4,
    });
    final int exerciseId = await db.database.insert('exercises', <String, Object?>{
      'name': 'Walking',
      'muscle_group': 'Cardio',
    });

    final ProgressRepository repository = ProgressRepository(db.database);
    final empty = await repository.getDayDetail(DateTime(2026, 10, 27, 23, 59));
    expect(empty.isEmpty, isTrue);
    expect(empty.foods, isEmpty);
    expect(empty.workouts, isEmpty);
    expect(empty.weightKg, isNull);
    expect(empty.day, DateTime(2026, 10, 27));

    await db.database.insert('food_logs', <String, Object?>{
      'date': '2026-10-28',
      'meal': 'lunch',
      'food_id': foodId,
      'unit_id': unitId,
      'quantity': 1.5,
      'tadka': 'medium',
      'calories': 270,
      'protein': 15,
      'carbs': 30,
      'fat': 6,
      'created_at': 'real',
    });
    final int sessionId = await db.database.insert('workout_sessions', <String, Object?>{
      'name': 'Walk',
      'date': '2026-10-28',
      'started_at': '2026-10-28T08:00:00',
      'ended_at': '2026-10-28T08:30:00',
      'duration_min': 30,
      'total_sets': 1,
      'est_kcal_burned': 175,
    });
    await db.database.insert('workout_sets', <String, Object?>{
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_number': 1,
      'weight_kg': 0,
      'reps': 0,
      'minutes': 30,
      'completed': 1,
    });
    await db.database.insert('weight_logs', <String, Object?>{
      'weight_kg': 71.2,
      'logged_at': '2026-10-28',
    });

    final morning = await repository.getDayDetail(DateTime(2026, 10, 28, 0, 5));
    expect(morning.day, DateTime(2026, 10, 28));
    expect(morning.foods, hasLength(1));
    expect(morning.foods.single.emoji, '🥣');
    expect(morning.foods.single.calories, 270);
    expect(morning.eatenKcal, 270);
    expect(morning.workouts, hasLength(1));
    expect(morning.workouts.single.sets, hasLength(1));
    expect(morning.burnedKcal, 175);
    expect(morning.netKcal, 270 - 175);
    expect(morning.weightKg, 71.2);
    expect(morning.isEmpty, isFalse);

    final previous = await repository.getDayDetail(DateTime(2026, 10, 27, 23, 59));
    expect(previous.isEmpty, isTrue);

    final next = await repository.getDayDetail(DateTime(2026, 10, 29, 0, 1));
    expect(next.isEmpty, isTrue);
  });
}
