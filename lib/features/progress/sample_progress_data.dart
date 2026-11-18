import 'package:sqflite/sqflite.dart';

import '../../data/repositories/progress_repository.dart';
import '../../domain/progress_calc.dart';

// How it works: debug only. Rows are marked so Clear sample data
// cannot delete a meal the person actually logged.

class SampleProgressData {
  SampleProgressData(this._database);

  final Database _database;

  Future<void> generate() async {
    final List<Map<String, Object?>> units = await _database.rawQuery(
      '''
      SELECT foods.id AS food_id, serving_units.id AS unit_id
      FROM foods
      INNER JOIN serving_units ON serving_units.food_id = foods.id
      LIMIT 1
      ''',
    );
    if (units.isEmpty) {
      return;
    }
    final int foodId = (units.first['food_id'] as num).toInt();
    final int unitId = (units.first['unit_id'] as num).toInt();
    final DateTime today = DateTime.now();
    final int? exerciseId = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT id FROM exercises LIMIT 1'),
    );

    await _database.transaction((Transaction txn) async {
      for (int ago = 29; ago >= 0; ago--) {
        final DateTime day = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: ago));
        final int calories = 1600 + ((ago * 37) % 900);
        await txn.insert('food_logs', <String, Object?>{
          'date': progressDayKey(day),
          'meal': 'lunch',
          'food_id': foodId,
          'unit_id': unitId,
          'quantity': 1,
          'calories': calories,
          'protein': 70 + (ago % 40),
          'carbs': 180 + (ago % 50),
          'fat': 50 + (ago % 20),
          'created_at': ProgressRepository.sampleCreatedAt,
        });
        if (ago % 3 == 0) {
          final int sessionId = await txn.insert('workout_sessions', <String, Object?>{
            'name': ProgressRepository.sampleSessionName,
            'date': progressDayKey(day),
            'started_at': '${progressDayKey(day)}T08:00:00',
            'ended_at': '${progressDayKey(day)}T08:40:00',
            'duration_min': 40,
            'total_sets': 4,
            'est_kcal_burned': 180 + (ago % 5) * 20,
          });
          if (exerciseId != null) {
            await txn.insert('workout_sets', <String, Object?>{
              'session_id': sessionId,
              'exercise_id': exerciseId,
              'set_number': 1,
              'weight_kg': 20,
              'reps': 8,
              'completed': 1,
            });
          }
        }
        if (ago % 5 == 0) {
          await txn.insert('weight_logs', <String, Object?>{
            'weight_kg': 72 - (ago * 0.15),
            'logged_at': '${progressDayKey(day)} sample',
          });
        }
      }
    });
  }

  Future<void> clear() async {
    final List<Map<String, Object?>> sessions = await _database.query(
      'workout_sessions',
      columns: <String>['id'],
      where: 'name = ?',
      whereArgs: <Object>[ProgressRepository.sampleSessionName],
    );
    final List<int> ids = <int>[
      for (final Map<String, Object?> row in sessions) (row['id'] as num).toInt(),
    ];
    await _database.transaction((Transaction txn) async {
      await txn.delete(
        'food_logs',
        where: 'created_at = ?',
        whereArgs: <Object>[ProgressRepository.sampleCreatedAt],
      );
      for (final int id in ids) {
        await txn.delete(
          'workout_sets',
          where: 'session_id = ?',
          whereArgs: <Object>[id],
        );
      }
      await txn.delete(
        'workout_sessions',
        where: 'name = ?',
        whereArgs: <Object>[ProgressRepository.sampleSessionName],
      );
      await txn.delete(
        'weight_logs',
        where: 'logged_at LIKE ? OR logged_at LIKE ?',
        whereArgs: <Object>[
          '${ProgressRepository.sampleWeightPrefix}%',
          '% sample',
        ],
      );
    });
  }
}
