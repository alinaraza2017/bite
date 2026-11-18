import 'package:sqflite/sqflite.dart';

import '../../domain/models.dart';
import '../../services/nutrition_service.dart';
import '../models/daily_totals.dart';
import '../models/food.dart';
import '../models/food_unit.dart';
import '../models/logged_food.dart';

// How it works: the numbers are calculated once, then stored on the log.
// Later edits to the food table do not change yesterday's plate.

class LogRepository {
  LogRepository(this._database);

  final Database _database;

  void Function()? onChanged;
  final List<void Function()> _watchers = <void Function()>[];

  /// Extra listeners. Home already uses [onChanged], so Progress can subscribe too.
  void addOnChanged(void Function() listener) {
    _watchers.add(listener);
  }

  void removeOnChanged(void Function() listener) {
    _watchers.remove(listener);
  }

  /// Tells Home and Progress that a log changed.
  void notifyChanged() {
    _emit();
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

  Future<List<LoggedFood>> foodsForDate(String date) async {
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
      <Object>[date],
    );
    return rows.map(LoggedFood.fromMap).toList();
  }

  Future<DailyTotals> totalsForDate(String date) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT COALESCE(SUM(calories), 0) AS kcal,
             COALESCE(SUM(protein), 0) AS protein,
             COALESCE(SUM(carbs), 0) AS carbs,
             COALESCE(SUM(fat), 0) AS fat
      FROM food_logs
      WHERE date = ?
      ''',
      <Object>[date],
    );
    if (rows.isEmpty) {
      return DailyTotals.zero;
    }
    return DailyTotals.fromMap(rows.first);
  }

  Future<LoggedFood> addLog({
    required String date,
    required String meal,
    required Food food,
    required FoodUnit unit,
    required double quantity,
    required TadkaLevel? tadka,
  }) async {
    final PortionNumbers numbers = _numbers(food, unit, quantity, tadka);
    final int id = await _database.insert('food_logs', <String, Object?>{
      'date': date,
      'meal': meal,
      'food_id': food.id,
      'unit_id': unit.id,
      'quantity': quantity,
      'tadka': food.hasTadka ? tadka?.name : null,
      'calories': numbers.calories,
      'protein': numbers.protein,
      'carbs': numbers.carbs,
      'fat': numbers.fat,
      'created_at': DateTime.now().toIso8601String(),
    });
    _emit();
    return _byId(id);
  }

  Future<void> updateLog({
    required int id,
    required String meal,
    required Food food,
    required FoodUnit unit,
    required double quantity,
    required TadkaLevel? tadka,
  }) async {
    final PortionNumbers numbers = _numbers(food, unit, quantity, tadka);
    await _database.update(
      'food_logs',
      <String, Object?>{
        'meal': meal,
        'unit_id': unit.id,
        'quantity': quantity,
        'tadka': food.hasTadka ? tadka?.name : null,
        'calories': numbers.calories,
        'protein': numbers.protein,
        'carbs': numbers.carbs,
        'fat': numbers.fat,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    _emit();
  }

  Future<LoggedFood?> deleteLog(int id) async {
    final LoggedFood row = await _byId(id);
    await _database.delete(
      'food_logs',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    _emit();
    return row;
  }

  Future<void> restoreLog(LoggedFood row) async {
    await _database.insert('food_logs', <String, Object?>{
      'id': row.id,
      'date': row.date,
      'meal': row.meal,
      'food_id': row.foodId,
      'unit_id': row.unitId,
      'quantity': row.quantity,
      'tadka': row.tadka,
      'calories': row.calories,
      'protein': row.protein,
      'carbs': row.carbs,
      'fat': row.fat,
      'created_at': DateTime.now().toIso8601String(),
    });
    _emit();
  }

  PortionNumbers _numbers(
    Food food,
    FoodUnit unit,
    double quantity,
    TadkaLevel? tadka,
  ) {
    return estimatePortion(
      unitCalories: unit.calories,
      unitProtein: unit.protein,
      unitCarbs: unit.carbs,
      unitFat: unit.fat,
      quantity: quantity,
      hasTadka: food.hasTadka,
      tadka: tadka ?? TadkaLevel.medium,
      tadkaLightKcal: food.tadkaLightKcal,
      tadkaLightFat: food.tadkaLightFat,
      tadkaHeavyKcal: food.tadkaHeavyKcal,
      tadkaHeavyFat: food.tadkaHeavyFat,
    );
  }

  Future<LoggedFood> _byId(int id) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT food_logs.*, foods.name AS food_name, foods.category AS category,
             foods.emoji AS food_emoji,
             foods.has_tadka AS has_tadka, serving_units.label AS unit_label
      FROM food_logs
      INNER JOIN foods ON foods.id = food_logs.food_id
      INNER JOIN serving_units ON serving_units.id = food_logs.unit_id
      WHERE food_logs.id = ?
      ''',
      <Object>[id],
    );
    return LoggedFood.fromMap(rows.first);
  }
}
