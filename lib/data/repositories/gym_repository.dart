import 'package:sqflite/sqflite.dart';

import '../../domain/burn_calc.dart';
import '../../domain/feature_gate.dart';
import '../../domain/pr_calc.dart';
import '../../domain/progress_calc.dart';
import '../models/gym_models.dart';

// How it works: a session stays open until Finish writes the end time.
// Burned kcal is the sum of each exercise. A locked exercise cannot be saved
// unless the account is premium. Previous set is the last finished one.

class WorkoutRepository {
  WorkoutRepository(this._database);

  final Database _database;

  void Function()? onChanged;
  final List<void Function()> _watchers = <void Function()>[];

  /// Extra listeners so Progress reloads without replacing Home's callback.
  void addOnChanged(void Function() listener) {
    _watchers.add(listener);
  }

  void removeOnChanged(void Function() listener) {
    _watchers.remove(listener);
  }

  void _emit() {
    final void Function()? notify = onChanged;
    if (notify != null) {
      notify();
    }
    for (final void Function() listener in List<void Function()>.of(_watchers)) {
      listener();
    }
  }

  Future<List<Exercise>> searchExercises(
    String query, {
    String? muscleGroup,
    int limit = 50,
  }) async {
    final String text = query.trim().toLowerCase();
    final bool hasQuery = text.isNotEmpty;
    final String match = hasQuery
        ? '''
        (
          LOWER(name) LIKE '%' || ? || '%'
          OR LOWER(IFNULL(aliases, '')) LIKE '%' || ? || '%'
        )
        '''
        : '1 = 1';
    final List<Object?> args = <Object?>[];
    if (hasQuery) {
      args.add(text);
      args.add(text);
    }
    args.add(muscleGroup);
    args.add(muscleGroup);
    if (hasQuery) {
      args.add(text);
      args.add(text);
      args.add(text);
      args.add(text);
    }
    args.add(limit);
    // Two full statements. An empty slot in ORDER BY is read as column 0.
    final String sql = hasQuery
        ? '''
      SELECT * FROM exercises
      WHERE $match
        AND (? IS NULL OR muscle_group = ?)
      ORDER BY
        (is_free = 1) DESC,
        (LOWER(name) = 'walking') DESC,
        (LOWER(name) = 'running') DESC,
        CASE
          WHEN LOWER(name) = ? THEN 0
          WHEN INSTR(',' || LOWER(IFNULL(aliases, '')) || ',', ',' || ? || ',') > 0 THEN 0
          WHEN LOWER(name) LIKE ? || '%' THEN 1
          WHEN INSTR(',' || LOWER(IFNULL(aliases, '')) || ',', ',' || ?) > 0 THEN 1
          ELSE 2
        END,
        name COLLATE NOCASE
      LIMIT ?
      '''
        : '''
      SELECT * FROM exercises
      WHERE $match
        AND (? IS NULL OR muscle_group = ?)
      ORDER BY
        (is_free = 1) DESC,
        (LOWER(name) = 'walking') DESC,
        (LOWER(name) = 'running') DESC,
        name COLLATE NOCASE
      LIMIT ?
      ''';
    final List<Map<String, Object?>> rows = await _database.rawQuery(sql, args);
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<String>> muscleGroups() async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      'SELECT DISTINCT muscle_group FROM exercises',
    );
    return <String>[
      for (final Map<String, Object?> row in rows)
        if (row['muscle_group'] != null) row['muscle_group'] as String,
    ];
  }

  Future<Exercise?> exerciseById(int id) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'exercises',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return Exercise.fromMap(rows.first);
  }

  Future<List<WorkoutTemplate>> templates() async {
    final List<Map<String, Object?>> rows = await _database.query(
      'workout_templates',
      orderBy: 'id ASC',
    );
    final List<WorkoutTemplate> plans = <WorkoutTemplate>[];
    for (final Map<String, Object?> row in rows) {
      final int id = (row['id'] as num).toInt();
      final List<Map<String, Object?>> exercises = await _database.rawQuery(
        '''
        SELECT exercises.*
        FROM workout_template_exercises
        INNER JOIN exercises ON exercises.id = workout_template_exercises.exercise_id
        WHERE template_id = ?
        ORDER BY position ASC
        ''',
        <Object>[id],
      );
      plans.add(
        WorkoutTemplate(
          id: id,
          name: row['name'] as String,
          exercises: exercises.map(Exercise.fromMap).toList(),
        ),
      );
    }
    return plans;
  }

  Future<WorkoutSummary?> openSession() async {
    final List<Map<String, Object?>> rows = await _database.query(
      'workout_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return WorkoutSummary.fromMap(rows.first);
  }

  Future<WorkoutSummary?> sessionById(int id) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return WorkoutSummary.fromMap(rows.first);
  }

  Future<int> startSession({
    required String name,
    int? templateId,
    required List<Exercise> exercises,
    bool isPremium = false,
  }) async {
    for (final Exercise exercise in exercises) {
      await _guard(exercise.id, isPremium);
    }
    final DateTime now = DateTime.now();
    final int sessionId = await _database.insert(
      'workout_sessions',
      <String, Object?>{
        'template_id': templateId,
        'name': name,
        'date': progressDayKey(now),
        'started_at': now.toIso8601String(),
      },
    );
    for (final Exercise exercise in exercises) {
      await _database.insert('workout_sets', <String, Object?>{
        'session_id': sessionId,
        'exercise_id': exercise.id,
        'set_number': 1,
        'weight_kg': 0,
        'reps': 0,
        'minutes': 0,
        'hold_seconds': 0,
        'completed': 0,
      });
    }
    _emit();
    return sessionId;
  }

  Future<void> addExercise(
    int sessionId,
    int exerciseId, {
    bool isPremium = false,
  }) async {
    await _guard(exerciseId, isPremium);
    await _database.insert('workout_sets', <String, Object?>{
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_number': 1,
      'weight_kg': 0,
      'reps': 0,
      'minutes': 0,
      'hold_seconds': 0,
      'completed': 0,
    });
    _emit();
  }

  Future<List<SessionSet>> setsForSession(int sessionId) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT workout_sets.*, exercises.name AS exercise_name,
             exercises.emoji AS exercise_emoji,
             exercises.type AS exercise_type
      FROM workout_sets
      INNER JOIN exercises ON exercises.id = workout_sets.exercise_id
      WHERE session_id = ?
      ORDER BY exercise_name COLLATE NOCASE, set_number ASC
      ''',
      <Object>[sessionId],
    );
    return rows.map(SessionSet.fromMap).toList();
  }

  Future<LastSet?> previousSet(int exerciseId, {int? ignoreSessionId}) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT workout_sets.weight_kg, workout_sets.reps,
             workout_sets.minutes, workout_sets.hold_seconds,
             workout_sets.variant_label
      FROM workout_sets
      INNER JOIN workout_sessions ON workout_sessions.id = workout_sets.session_id
      WHERE workout_sets.exercise_id = ?
        AND workout_sets.completed = 1
        AND workout_sessions.ended_at IS NOT NULL
        AND (? IS NULL OR workout_sessions.id != ?)
      ORDER BY workout_sessions.ended_at DESC, workout_sets.set_number DESC
      LIMIT 1
      ''',
      <Object?>[exerciseId, ignoreSessionId, ignoreSessionId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return LastSet(
      weightKg: (rows.first['weight_kg'] as num).toDouble(),
      reps: (rows.first['reps'] as num).toInt(),
      minutes: (rows.first['minutes'] as num?)?.toInt() ?? 0,
      holdSeconds: (rows.first['hold_seconds'] as num?)?.toInt() ?? 0,
      variantLabel: rows.first['variant_label'] as String?,
    );
  }

  Future<void> saveSet({
    required int sessionId,
    required int exerciseId,
    required int setNumber,
    required double weightKg,
    required int reps,
    int? existingId,
    int minutes = 0,
    int holdSeconds = 0,
    String? variantLabel,
    bool isPremium = false,
  }) async {
    await _guard(exerciseId, isPremium);
    final Map<String, Object?> values = <String, Object?>{
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'minutes': minutes,
      'hold_seconds': holdSeconds,
      'variant_label': variantLabel,
      'completed': 1,
    };
    if (existingId == null) {
      await _database.insert('workout_sets', values);
    } else {
      await _database.update(
        'workout_sets',
        values,
        where: 'id = ?',
        whereArgs: <Object>[existingId],
      );
    }
    _emit();
  }

  Future<void> deleteSet(int id) async {
    await _database.delete(
      'workout_sets',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    _emit();
  }

  Future<WorkoutSummary> finishSession(
    int sessionId, {
    double? logWeightKg,
    double? profileWeightKg,
  }) async {
    final WorkoutSummary? session = await sessionById(sessionId);
    final DateTime end = DateTime.now();
    final DateTime start = DateTime.tryParse(session?.startedAt ?? '') ?? end;
    int minutes = end.difference(start).inMinutes;
    if (minutes < 1) {
      minutes = 1;
    }
    final int? sets = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM workout_sets WHERE session_id = ? AND completed = 1',
        <Object>[sessionId],
      ),
    );
    final double? logged = logWeightKg ?? await latestLoggedWeightKg();
    final double weightKg = resolveBodyWeightKg(
      logKg: logged,
      profileKg: profileWeightKg,
    );
    final int burned = await _burnForSession(sessionId, weightKg);
    await _database.update(
      'workout_sessions',
      <String, Object?>{
        'ended_at': end.toIso8601String(),
        'duration_min': minutes,
        'total_sets': sets ?? 0,
        'est_kcal_burned': burned,
      },
      where: 'id = ?',
      whereArgs: <Object>[sessionId],
    );
    _emit();
    return (await sessionById(sessionId))!;
  }

  Future<List<WorkoutSummary>> recentSessions({int limit = 20}) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'workout_sessions',
      where: 'ended_at IS NOT NULL',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(WorkoutSummary.fromMap).toList();
  }

  Future<int> sessionsOnDate(String date) async {
    final int? count = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM workout_sessions WHERE date = ? AND ended_at IS NOT NULL',
        <Object>[date],
      ),
    );
    return count ?? 0;
  }

  Future<double> burnedForDate(String date) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT COALESCE(SUM(est_kcal_burned), 0) AS burned
      FROM workout_sessions
      WHERE date = ? AND ended_at IS NOT NULL
      ''',
      <Object>[date],
    );
    return (rows.first['burned'] as num?)?.toDouble() ?? 0;
  }

  /// Newest row in weight_logs, if the person has logged a weigh-in.
  Future<double?> latestLoggedWeightKg() async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      'SELECT weight_kg FROM weight_logs ORDER BY logged_at DESC, id DESC LIMIT 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    return (rows.first['weight_kg'] as num).toDouble();
  }

  /// Best finished set for this exercise, by Epley one-rep max.
  Future<LastSet?> bestEffort(int exerciseId) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT workout_sets.weight_kg, workout_sets.reps
      FROM workout_sets
      INNER JOIN workout_sessions ON workout_sessions.id = workout_sets.session_id
      WHERE workout_sets.exercise_id = ?
        AND workout_sets.completed = 1
        AND workout_sessions.ended_at IS NOT NULL
        AND workout_sets.weight_kg > 0
        AND workout_sets.reps > 0
      ''',
      <Object>[exerciseId],
    );
    LastSet? best;
    double bestMax = 0;
    for (final Map<String, Object?> row in rows) {
      final double weight = (row['weight_kg'] as num).toDouble();
      final int reps = (row['reps'] as num).toInt();
      final double oneRep = epleyOneRepMax(weight, reps);
      if (oneRep > bestMax) {
        bestMax = oneRep;
        best = LastSet(weightKg: weight, reps: reps);
      }
    }
    return best;
  }

  Future<int> createCustomExercise({
    required String name,
    required String muscleGroup,
    bool isPremium = false,
  }) async {
    if (!FeatureGate(isPremium: isPremium).canUse(Feature.customExercises)) {
      throw const PremiumRequired();
    }
    final String clean = name.trim();
    if (clean.isEmpty) {
      throw ArgumentError('An exercise needs a name.');
    }
    return _database.insert('exercises', <String, Object?>{
      'name': clean,
      'muscle_group': muscleGroup.trim().isEmpty ? 'Full Body' : muscleGroup.trim(),
      'type': 'strength',
      'met': 5,
      'is_free': 0,
      'is_custom': 1,
      'emoji': '💪',
    });
  }

  Future<void> _guard(int exerciseId, bool isPremium) async {
    final Exercise? exercise = await exerciseById(exerciseId);
    if (exercise == null) {
      throw StateError('That exercise is missing.');
    }
    final bool allowed = canLogExercise(
      isPremium: isPremium,
      isFree: exercise.isFree,
      isCustom: exercise.isCustom,
    );
    if (!allowed) {
      throw const PremiumRequired();
    }
  }

  Future<int> _burnForSession(int sessionId, double weightKg) async {
    final List<SessionSet> sets = await setsForSession(sessionId);
    final Map<int, List<SessionSet>> grouped = <int, List<SessionSet>>{};
    for (final SessionSet set in sets) {
      if (!set.completed) {
        continue;
      }
      grouped.putIfAbsent(set.exerciseId, () => <SessionSet>[]).add(set);
    }
    int total = 0;
    for (final MapEntry<int, List<SessionSet>> entry in grouped.entries) {
      final Exercise? exercise = await exerciseById(entry.key);
      if (exercise == null) {
        continue;
      }
      total += _burnOne(exercise, entry.value, weightKg);
    }
    return total;
  }

  int _burnOne(Exercise exercise, List<SessionSet> sets, double weightKg) {
    if (exercise.type == 'duration') {
      int minutes = 0;
      double met = exercise.met;
      for (final SessionSet set in sets) {
        minutes += set.minutes;
        final ExerciseVariant? variant = exercise.variantByLabel(set.variantLabel);
        if (variant != null) {
          met = variant.met;
        }
      }
      return durationBurn(met: met, weightKg: weightKg, minutes: minutes);
    }
    if (exercise.type == 'timed') {
      int active = 0;
      for (final SessionSet set in sets) {
        active += set.holdSeconds + restSecondsAfterTimedSet;
      }
      return burnFromActiveSeconds(
        met: exercise.met,
        weightKg: weightKg,
        activeSeconds: active,
      );
    }
    return strengthBurn(met: exercise.met, weightKg: weightKg, sets: sets.length);
  }

  /// Which template was finished least recently. Never-done plans come first.
  Future<WorkoutTemplate?> nextTemplate(List<WorkoutTemplate> plans) async {
    if (plans.isEmpty) {
      return null;
    }
    WorkoutTemplate? oldest = plans.first;
    String? oldestDate = await _lastDone(plans.first.id);
    for (final WorkoutTemplate plan in plans.skip(1)) {
      final String? date = await _lastDone(plan.id);
      final bool neverDone = date == null && oldestDate != null;
      final bool older =
          date != null && oldestDate != null && date.compareTo(oldestDate) < 0;
      if (neverDone || older) {
        oldest = plan;
        oldestDate = date;
      }
    }
    return oldest;
  }

  Future<String?> _lastDone(int templateId) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT date FROM workout_sessions
      WHERE template_id = ? AND ended_at IS NOT NULL
      ORDER BY date DESC
      LIMIT 1
      ''',
      <Object>[templateId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['date'] as String;
  }
}
