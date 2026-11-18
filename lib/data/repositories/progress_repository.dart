import 'package:sqflite/sqflite.dart';

import '../../domain/progress_calc.dart';
import '../../domain/progress_report.dart';
import '../models/day_detail.dart';
import '../models/gym_models.dart';
import '../models/logged_food.dart';

// How it works: one query per table for the window, then the domain
// fills the missing days. Sample rows are marked so Clear can see them.

class ProgressRepository {
  ProgressRepository(this._database);

  final Database _database;

  static const String sampleCreatedAt = 'sample-progress';
  static const String sampleSessionName = 'Sample session';
  static const String sampleWeightPrefix = 'sample:';

  Future<ProgressReport> load({
    required DateTime today,
    required int dayCount,
    required int calorieTarget,
    required double proteinTarget,
  }) async {
    final DateTime end = DateTime(today.year, today.month, today.day);
    final String endKey = progressDayKey(end);
    final String startKey = rangeStartKey(end, dayCount);
    final Map<String, DayTotals> days = <String, DayTotals>{};

    final List<Map<String, Object?>> foodRows = await _database.rawQuery(
      '''
      SELECT date,
             SUM(calories) AS eaten,
             SUM(protein) AS protein,
             SUM(carbs) AS carbs,
             SUM(fat) AS fat,
             COUNT(*) AS logs
      FROM food_logs
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ''',
      <Object>[startKey, endKey],
    );
    for (final Map<String, Object?> row in foodRows) {
      final String date = row['date'] as String;
      days[date] = DayTotals(
        eatenKcal: (row['eaten'] as num?)?.round() ?? 0,
        protein: (row['protein'] as num?)?.toDouble() ?? 0,
        carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
        fat: (row['fat'] as num?)?.toDouble() ?? 0,
        loggedFood: ((row['logs'] as num?)?.toInt() ?? 0) > 0,
      );
    }

    final List<Map<String, Object?>> workoutRows = await _database.rawQuery(
      '''
      SELECT date,
             SUM(est_kcal_burned) AS burned,
             SUM(duration_min) AS minutes,
             COUNT(*) AS sessions
      FROM workout_sessions
      WHERE ended_at IS NOT NULL AND date >= ? AND date <= ?
      GROUP BY date
      ''',
      <Object>[startKey, endKey],
    );
    for (final Map<String, Object?> row in workoutRows) {
      final String date = row['date'] as String;
      final DayTotals previous = days[date] ?? const DayTotals();
      days[date] = DayTotals(
        eatenKcal: previous.eatenKcal,
        protein: previous.protein,
        carbs: previous.carbs,
        fat: previous.fat,
        loggedFood: previous.loggedFood,
        burnedKcal: (row['burned'] as num?)?.round() ?? 0,
        minutes: (row['minutes'] as num?)?.round() ?? 0,
        workouts: (row['sessions'] as num?)?.toInt() ?? 0,
      );
    }

    final List<Map<String, Object?>> weightRows = await _database.rawQuery(
      '''
      SELECT logged_at, weight_kg
      FROM weight_logs
      ORDER BY id ASC
      ''',
    );
    final List<WeightPoint> weights = <WeightPoint>[];
    for (final Map<String, Object?> row in weightRows) {
      final String? key = _weightDay(row['logged_at'] as String?);
      if (key == null || key.compareTo(startKey) < 0 || key.compareTo(endKey) > 0) {
        continue;
      }
      final DateTime? day = _dayFromKey(key);
      if (day == null) {
        continue;
      }
      weights.add(
        WeightPoint(day: day, kg: (row['weight_kg'] as num).toDouble()),
      );
    }

    final Set<String> allFoodDates = <String>{};
    final List<Map<String, Object?>> dateRows = await _database.rawQuery(
      'SELECT DISTINCT date FROM food_logs',
    );
    for (final Map<String, Object?> row in dateRows) {
      final Object? date = row['date'];
      if (date is String) {
        allFoodDates.add(date);
      }
    }

    final int? foodCount = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM food_logs'),
    );
    final int? workoutCount = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM workout_sessions WHERE ended_at IS NOT NULL',
      ),
    );

    return buildProgressReport(
      today: end,
      dayCount: dayCount,
      logged: days,
      allFoodDates: allFoodDates,
      weights: weights,
      calorieTarget: calorieTarget,
      proteinTarget: proteinTarget,
      hasAnyFood: (foodCount ?? 0) > 0,
      hasAnyWorkout: (workoutCount ?? 0) > 0,
    );
  }

  /// One calendar day. The key is yyyy-MM-dd in local time, not UTC.
  Future<DayDetail> getDayDetail(DateTime date) async {
    final DateTime day = DateTime(date.year, date.month, date.day);
    final String key = progressDayKey(day);
    final List<LoggedFood> foods = await _foods(key);
    final List<DayWorkoutDetail> workouts = await _workouts(key);
    int eaten = 0;
    for (final LoggedFood food in foods) {
      eaten += food.calories;
    }
    int burned = 0;
    for (final DayWorkoutDetail workout in workouts) {
      burned += workout.session.burnedKcal.round();
    }
    return DayDetail(
      day: day,
      foods: foods,
      workouts: workouts,
      weightKg: await _weightOn(key),
      eatenKcal: eaten,
      burnedKcal: burned,
    );
  }

  /// Kcal and a flag for each day that has a meal or a finished workout.
  Future<Map<String, DayMark>> marksBetween(String startKey, String endKey) async {
    final Map<String, DayMark> marks = <String, DayMark>{};
    final List<Map<String, Object?>> foods = await _database.rawQuery(
      '''
      SELECT date, SUM(calories) AS eaten
      FROM food_logs
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ''',
      <Object>[startKey, endKey],
    );
    for (final Map<String, Object?> row in foods) {
      final String? date = row['date'] as String?;
      if (date == null) {
        continue;
      }
      marks[date] = DayMark(
        eatenKcal: (row['eaten'] as num?)?.round() ?? 0,
        hasEntry: true,
      );
    }
    final List<Map<String, Object?>> sessions = await _database.rawQuery(
      '''
      SELECT DISTINCT date
      FROM workout_sessions
      WHERE ended_at IS NOT NULL AND date >= ? AND date <= ?
      ''',
      <Object>[startKey, endKey],
    );
    for (final Map<String, Object?> row in sessions) {
      final String? date = row['date'] as String?;
      if (date == null) {
        continue;
      }
      final DayMark previous = marks[date] ?? const DayMark();
      marks[date] = DayMark(eatenKcal: previous.eatenKcal, hasEntry: true);
    }
    return marks;
  }

  Future<List<LoggedFood>> _foods(String key) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT food_logs.*, foods.name AS food_name, foods.category AS category,
             foods.emoji AS food_emoji,
             foods.has_tadka AS has_tadka, serving_units.label AS unit_label
      FROM food_logs
      INNER JOIN foods ON foods.id = food_logs.food_id
      INNER JOIN serving_units ON serving_units.id = food_logs.unit_id
      WHERE food_logs.date = ?
      ORDER BY food_logs.id ASC
      ''',
      <Object>[key],
    );
    return rows.map(LoggedFood.fromMap).toList();
  }

  Future<List<DayWorkoutDetail>> _workouts(String key) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'workout_sessions',
      where: 'date = ? AND ended_at IS NOT NULL',
      whereArgs: <Object>[key],
      orderBy: 'id ASC',
    );
    final List<DayWorkoutDetail> workouts = <DayWorkoutDetail>[];
    for (final Map<String, Object?> row in rows) {
      final WorkoutSummary session = WorkoutSummary.fromMap(row);
      final List<Map<String, Object?>> sets = await _database.rawQuery(
        '''
        SELECT workout_sets.*, exercises.name AS exercise_name,
               exercises.emoji AS exercise_emoji,
               exercises.type AS exercise_type
        FROM workout_sets
        INNER JOIN exercises ON exercises.id = workout_sets.exercise_id
        WHERE session_id = ?
        ORDER BY exercise_name COLLATE NOCASE, set_number ASC
        ''',
        <Object>[session.id],
      );
      workouts.add(
        DayWorkoutDetail(
          session: session,
          sets: sets.map(SessionSet.fromMap).toList(),
        ),
      );
    }
    return workouts;
  }

  Future<double?> _weightOn(String key) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      'SELECT logged_at, weight_kg FROM weight_logs ORDER BY id ASC',
    );
    double? kg;
    for (final Map<String, Object?> row in rows) {
      if (_weightDay(row['logged_at'] as String?) != key) {
        continue;
      }
      kg = (row['weight_kg'] as num).toDouble();
    }
    return kg;
  }

  Future<void> addWeight(double kg) async {
    await _database.insert('weight_logs', <String, Object?>{
      'weight_kg': kg,
      'logged_at': progressDayKey(DateTime.now()),
    });
  }

  String? _weightDay(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw.startsWith(sampleWeightPrefix)) {
      return raw.substring(sampleWeightPrefix.length);
    }
    if (raw.length >= 10) {
      return raw.substring(0, 10);
    }
    return raw;
  }

  DateTime? _dayFromKey(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) {
      return null;
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
