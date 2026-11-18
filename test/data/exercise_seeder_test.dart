import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bite/data/repositories/gym_repository.dart';
import 'package:bite/data/seed/exercise_seeder.dart';

import 'test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merge keeps ids and only Walking and Running are free', () async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TestDatabase db = await openTestDatabase();

    final int benchId = await db.database.insert('exercises', <String, Object?>{
      'name': 'Bench Press',
      'muscle_group': 'Chest',
    });
    final int oldId = await db.database.insert('exercises', <String, Object?>{
      'name': 'Old Lift',
      'muscle_group': 'Arms',
      'met': 8,
      'is_free': 1,
    });
    final int customId = await db.database.insert('exercises', <String, Object?>{
      'name': 'My Lift',
      'muscle_group': 'Full Body',
      'is_custom': 1,
      'met': 9,
      'is_free': 1,
      'type': 'strength',
    });
    final int sessionId = await db.database.insert('workout_sessions', <String, Object?>{
      'name': 'Push',
      'date': '2026-10-01',
      'started_at': '2026-10-01T10:00:00',
      'ended_at': '2026-10-01T10:40:00',
      'est_kcal_burned': 210,
    });
    final int setId = await db.database.insert('workout_sets', <String, Object?>{
      'session_id': sessionId,
      'exercise_id': benchId,
      'set_number': 1,
      'weight_kg': 60,
      'reps': 8,
      'completed': 1,
    });

    await ExerciseSeeder().seed(db.database, preferences);

    final List<Map<String, Object?>> bench = await db.database.query(
      'exercises',
      where: 'id = ?',
      whereArgs: <Object>[benchId],
    );
    expect(bench, isNotEmpty);
    expect(bench.first['name'], 'Barbell Bench Press');
    expect((bench.first['is_free'] as num).toInt(), 0);
    expect(bench.first['type'], 'strength');

    final List<Map<String, Object?>> sets = await db.database.query(
      'workout_sets',
      where: 'id = ?',
      whereArgs: <Object>[setId],
    );
    expect(sets.single['exercise_id'], benchId);
    expect(sets.single['weight_kg'], 60);

    final List<Map<String, Object?>> old = await db.database.query(
      'exercises',
      where: 'id = ?',
      whereArgs: <Object>[oldId],
    );
    expect(old.single['type'], 'strength');
    expect(old.single['met'], 5);
    expect((old.single['is_free'] as num).toInt(), 0);

    final List<Map<String, Object?>> custom = await db.database.query(
      'exercises',
      where: 'id = ?',
      whereArgs: <Object>[customId],
    );
    expect(custom.single['met'], 9);
    expect((custom.single['is_custom'] as num).toInt(), 1);

    final List<Map<String, Object?>> free = await db.database.query(
      'exercises',
      columns: <String>['name'],
      where: 'is_free = 1 AND is_custom = 0',
      orderBy: 'name',
    );
    expect(
      free.map((Map<String, Object?> row) => row['name']).toList(),
      <String>['Running', 'Walking'],
    );

    final List<Map<String, Object?>> groups = await db.database.rawQuery(
      'SELECT muscle_group, COUNT(*) AS count FROM exercises GROUP BY muscle_group ORDER BY muscle_group',
    );
    int total = 0;
    for (final Map<String, Object?> row in groups) {
      final int count = (row['count'] as num).toInt();
      total += count;
      // ignore: avoid_print
      print('${row['muscle_group']}: $count');
    }
    // ignore: avoid_print
    print('TOTAL $total');
    expect(total, greaterThan(150));

    final WorkoutRepository workouts = WorkoutRepository(db.database);
    final all = await workouts.searchExercises('');
    expect(all, isNotEmpty);
    expect(all.first.name, 'Walking');
    expect(all[1].name, 'Running');
    final found = await workouts.searchExercises('chalna');
    expect(found.first.name, 'Walking');
    final sessions = await db.database.query('workout_sessions');
    expect(sessions, isNotEmpty);

    await ExerciseSeeder().seed(db.database, preferences);
    final int? after = Sqflite.firstIntValue(
      await db.database.rawQuery('SELECT COUNT(*) FROM exercises'),
    );
    expect(after, total);
    await db.close();
  });
}