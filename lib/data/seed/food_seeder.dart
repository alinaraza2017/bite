import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// How it works: seed 2 merges foods.json into the foods already on the phone.
// A food we already have keeps its id and its numbers. We only add aliases
// and unit labels that were missing. Custom foods and meal logs are left alone.

class FoodSeeder {
  FoodSeeder({this.assetPath = 'assets/data/foods.json'});

  final String assetPath;

  static const String seedVersionKey = 'seed_version';
  static const String categoryOrderKey = 'food_category_order';
  static const int thisSeedVersion = 2;

  Future<void> seed(Database database, SharedPreferences preferences) async {
    final int stored = preferences.getInt(seedVersionKey) ?? 0;
    if (stored >= thisSeedVersion) {
      return;
    }

    final String text = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('foods.json must be an object.');
    }
    final Object? list = decoded['foods'];
    if (list is! List<dynamic>) {
      throw StateError('foods.json needs a foods list.');
    }

    await _ensureColumns(database);
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category)',
    );

    final List<String> categoryOrder = <String>[];
    await database.transaction((Transaction txn) async {
      final Map<String, int> known = await _knownFoods(txn);
      for (final dynamic item in list) {
        final Map<String, dynamic> food = item as Map<String, dynamic>;
        final String? category = _text(food['category']);
        if (category != null && !categoryOrder.contains(category)) {
          categoryOrder.add(category);
        }
        await _mergeOne(txn, food, known);
      }
    });

    await preferences.setInt(seedVersionKey, thisSeedVersion);
    await preferences.setString(categoryOrderKey, jsonEncode(categoryOrder));
  }

  Future<void> _ensureColumns(Database database) async {
    const List<List<String>> columns = <List<String>>[
      <String>['aliases', 'TEXT'],
      <String>['emoji', 'TEXT'],
      <String>['kcal100', 'REAL'],
      <String>['protein100', 'REAL'],
      <String>['carbs100', 'REAL'],
      <String>['fat100', 'REAL'],
      <String>['is_favorite', 'INTEGER NOT NULL DEFAULT 0'],
    ];
    final List<Map<String, Object?>> info = await database.rawQuery(
      'PRAGMA table_info(foods)',
    );
    final Set<String> present = <String>{
      for (final Map<String, Object?> row in info) row['name'] as String,
    };
    for (final List<String> column in columns) {
      if (present.contains(column[0])) {
        continue;
      }
      await database.execute(
        'ALTER TABLE foods ADD COLUMN ${column[0]} ${column[1]}',
      );
    }
  }

  Future<Map<String, int>> _knownFoods(Transaction txn) async {
    final List<Map<String, Object?>> rows = await txn.query(
      'foods',
      columns: <String>['id', 'name', 'aliases'],
      where: 'is_custom = 0',
    );
    final Map<String, int> known = <String, int>{};
    for (final Map<String, Object?> row in rows) {
      final int id = (row['id'] as num).toInt();
      _remember(known, row['name'] as String, id);
      for (final String alias in _splitAliases(row['aliases'] as String?)) {
        _remember(known, alias, id);
      }
    }
    return known;
  }

  Future<void> _mergeOne(
    Transaction txn,
    Map<String, dynamic> food,
    Map<String, int> known,
  ) async {
    final String? name = _text(food['name']);
    final String? category = _text(food['category']);
    if (name == null || category == null) {
      return;
    }
    final List<String> aliases = _aliasList(food['aliases']);
    final int? existingId = _findExisting(known, name, aliases);
    if (existingId != null) {
      _remember(known, name, existingId);
      await _addMissingAliases(txn, existingId, <String>[name, ...aliases], known);
      await _addMissingUnits(txn, existingId, food, keepNutrition: true);
      return;
    }

    final int foodId = await txn.insert('foods', <String, Object?>{
      'name': name,
      'category': category,
      'aliases': aliases.isEmpty ? null : aliases.join(','),
      'emoji': _text(food['emoji']),
      'kcal100': _number(food['kcal100']),
      'protein100': _number(food['protein100']),
      'carbs100': _number(food['carbs100']),
      'fat100': _number(food['fat100']),
      'is_favorite': 0,
      'is_custom': 0,
      'has_tadka': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    _remember(known, name, foodId);
    for (final String alias in aliases) {
      _remember(known, alias, foodId);
    }
    await _addMissingUnits(txn, foodId, food, keepNutrition: false);
  }

  int? _findExisting(
    Map<String, int> known,
    String name,
    List<String> aliases,
  ) {
    final int? byName = known[name.toLowerCase()];
    if (byName != null) {
      return byName;
    }
    for (final String alias in aliases) {
      final int? byAlias = known[alias.toLowerCase()];
      if (byAlias != null) {
        return byAlias;
      }
    }
    return null;
  }

  Future<void> _addMissingAliases(
    Transaction txn,
    int foodId,
    List<String> incoming,
    Map<String, int> known,
  ) async {
    final List<Map<String, Object?>> rows = await txn.query(
      'foods',
      columns: <String>['aliases'],
      where: 'id = ?',
      whereArgs: <Object>[foodId],
    );
    if (rows.isEmpty) {
      return;
    }
    final List<String> have = _splitAliases(rows.first['aliases'] as String?);
    final Set<String> lower = <String>{
      for (final String alias in have) alias.toLowerCase(),
    };
    bool changed = false;
    for (final String alias in incoming) {
      if (lower.add(alias.toLowerCase())) {
        have.add(alias);
        changed = true;
      }
      _remember(known, alias, foodId);
    }
    if (!changed) {
      return;
    }
    await txn.update(
      'foods',
      <String, Object?>{'aliases': have.join(',')},
      where: 'id = ?',
      whereArgs: <Object>[foodId],
    );
  }

  Future<void> _addMissingUnits(
    Transaction txn,
    int foodId,
    Map<String, dynamic> food, {
    required bool keepNutrition,
  }) async {
    final Object? rawUnits = food['units'];
    if (rawUnits is! List<dynamic>) {
      return;
    }
    final List<Map<String, Object?>> current = await txn.query(
      'serving_units',
      columns: <String>['label', 'is_default'],
      where: 'food_id = ?',
      whereArgs: <Object>[foodId],
    );
    final Set<String> labels = <String>{
      for (final Map<String, Object?> row in current)
        (row['label'] as String).trim().toLowerCase(),
    };
    final bool alreadyDefault = current.any(
      (Map<String, Object?> row) => (row['is_default'] as num).toInt() == 1,
    );
    final double kcal100 = _number(food['kcal100']) ?? 0;
    final double protein100 = _number(food['protein100']) ?? 0;
    final double carbs100 = _number(food['carbs100']) ?? 0;
    final double fat100 = _number(food['fat100']) ?? 0;

    bool seenDefault = alreadyDefault;
    int? firstNewUnitId;
    for (final dynamic item in rawUnits) {
      final Map<String, dynamic> unit = item as Map<String, dynamic>;
      final String? label = _text(unit['label']);
      final double? grams = _number(unit['grams']);
      if (label == null || grams == null) {
        continue;
      }
      if (!labels.add(label.toLowerCase())) {
        continue;
      }
      final bool wantsDefault = unit['isDefault'] == true || unit['is_default'] == true;
      final bool makeDefault = wantsDefault && !seenDefault;
      if (makeDefault) {
        seenDefault = true;
      }
      // A new unit needs numbers. An old unit is never updated.
      final double calories = keepNutrition
          ? kcal100 * grams / 100
          : _number(unit['calories']) ?? kcal100 * grams / 100;
      final double protein = keepNutrition
          ? protein100 * grams / 100
          : _number(unit['protein']) ?? protein100 * grams / 100;
      final double carbs = keepNutrition
          ? carbs100 * grams / 100
          : _number(unit['carbs']) ?? carbs100 * grams / 100;
      final double fat = keepNutrition
          ? fat100 * grams / 100
          : _number(unit['fat']) ?? fat100 * grams / 100;
      final int unitId = await txn.insert('serving_units', <String, Object?>{
        'food_id': foodId,
        'label': label,
        'grams': grams,
        'is_default': makeDefault ? 1 : 0,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      });
      firstNewUnitId ??= unitId;
    }
    if (!seenDefault && firstNewUnitId != null) {
      await txn.update(
        'serving_units',
        <String, Object?>{'is_default': 1},
        where: 'id = ?',
        whereArgs: <Object>[firstNewUnitId],
      );
    }
  }

  void _remember(Map<String, int> known, String token, int id) {
    final String key = token.trim().toLowerCase();
    if (key.isEmpty) {
      return;
    }
    known.putIfAbsent(key, () => id);
  }

  List<String> _aliasList(Object? raw) {
    if (raw is! List<dynamic>) {
      return <String>[];
    }
    final List<String> aliases = <String>[];
    final Set<String> seen = <String>{};
    for (final dynamic item in raw) {
      final String? alias = _text(item);
      if (alias == null) {
        continue;
      }
      if (seen.add(alias.toLowerCase())) {
        aliases.add(alias);
      }
    }
    return aliases;
  }

  List<String> _splitAliases(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }
    return <String>[
      for (final String part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  String? _text(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  double? _number(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return null;
  }
}
