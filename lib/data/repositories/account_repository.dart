import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Reads the current tables into one JSON object, and can wipe personal rows.
class AccountRepository {
  AccountRepository(this._database);

  final Database _database;

  Future<Map<String, Object?>> snapshot({
    required Map<String, Object?>? profile,
    required String weightUnit,
    required bool isPremium,
  }) async {
    return {
      'profile': profile,
      'foods': await _database.query('foods'),
      'foodUnits': await _database.query('serving_units'),
      'logs': await _database.query('food_logs'),
      'exercises': await _database.query('exercises'),
      'workouts': await _database.query('workout_sessions'),
      'sets': await _database.query('workout_sets'),
      'weights': <Map<String, Object?>>[],
      'settings': {
        'weightUnit': weightUnit,
        'isPremium': isPremium,
      },
    };
  }

  Future<String> exportJson({
    required Map<String, Object?>? profile,
    required String weightUnit,
    required bool isPremium,
  }) async {
    final Map<String, Object?> data = await snapshot(
      profile: profile,
      weightUnit: weightUnit,
      isPremium: isPremium,
    );
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Logs, workouts, and custom foods. Seeded foods stay.
  Future<void> resetTables() async {
    await _database.transaction((Transaction txn) async {
      await txn.delete('food_logs');
      await txn.delete('workout_sets');
      await txn.delete('workout_sessions');
      await txn.delete('foods', where: 'is_custom = 1');
    });
  }
}
