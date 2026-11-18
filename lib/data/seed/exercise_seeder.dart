import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database.dart';

// How it works: seed 2 merges exercises.json into the rows already on the phone.
// A match keeps its id so old sets still point at it. Custom exercises and
// finished workouts are never deleted.

class ExerciseSeeder {
  ExerciseSeeder({this.assetPath = 'assets/data/exercises.json'});

  final String assetPath;

  static const String seedVersionKey = 'exercise_seed_version';
  static const String groupOrderKey = 'exercise_group_order';
  static const int thisSeedVersion = 2;

  Future<void> seed(Database database, SharedPreferences preferences) async {
    final int stored = preferences.getInt(seedVersionKey) ?? 0;
    if (stored >= thisSeedVersion) {
      return;
    }
    final String text = await rootBundle.loadString(assetPath);
    await seedFromText(database, preferences, text);
  }

  /// Used by tests so they can pass the catalog without the asset bundle.
  Future<void> seedFromText(
    Database database,
    SharedPreferences preferences,
    String text,
  ) async {
    final int stored = preferences.getInt(seedVersionKey) ?? 0;
    if (stored >= thisSeedVersion) {
      return;
    }
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('exercises.json must be an object.');
    }
    final Object? list = decoded['exercises'];
    if (list is! List<dynamic>) {
      throw StateError('exercises.json needs an exercises list.');
    }

    await upgradeBiteToV4(database);
    final List<String> groupOrder = <String>[];
    final Set<int> matched = <int>{};

    await database.transaction((Transaction txn) async {
      final Map<String, int> known = await _known(txn);
      for (final dynamic item in list) {
        final Map<String, dynamic> exercise = item as Map<String, dynamic>;
        final String? group = _text(exercise['muscleGroup']);
        if (group != null && !groupOrder.contains(group)) {
          groupOrder.add(group);
        }
        final int? id = await _mergeOne(txn, exercise, known);
        if (id != null) {
          matched.add(id);
        }
      }
      await _markLeftovers(txn, matched);
      await _onlyWalkingAndRunningAreFree(txn);
    });

    await preferences.setInt(seedVersionKey, thisSeedVersion);
    await preferences.setString(groupOrderKey, jsonEncode(groupOrder));
  }

  Future<Map<String, int>> _known(Transaction txn) async {
    final List<Map<String, Object?>> rows = await txn.query(
      'exercises',
      columns: <String>['id', 'name', 'aliases', 'is_custom'],
    );
    final Map<String, int> known = <String, int>{};
    for (final Map<String, Object?> row in rows) {
      if ((row['is_custom'] as num?)?.toInt() == 1) {
        continue;
      }
      final int id = (row['id'] as num).toInt();
      _remember(known, row['name'] as String?, id);
      for (final String alias in _split(row['aliases'] as String?)) {
        _remember(known, alias, id);
      }
    }
    return known;
  }

  Future<int?> _mergeOne(
    Transaction txn,
    Map<String, dynamic> exercise,
    Map<String, int> known,
  ) async {
    final String? name = _text(exercise['name']);
    final String? group = _text(exercise['muscleGroup']);
    if (name == null || group == null) {
      return null;
    }
    final List<String> aliases = _aliasList(exercise['aliases']);
    final int? existing = _find(known, name, aliases);
    final Map<String, Object?> values = <String, Object?>{
      'name': name,
      'muscle_group': group,
      'aliases': aliases.join(','),
      'emoji': _text(exercise['emoji']),
      'type': _type(exercise['type']),
      'equipment': _text(exercise['equipment']),
      'met': _number(exercise['met']) ?? 5,
      'is_free': _isFreeName(name),
      'variants_json': _variantsText(exercise['variants']),
    };
    if (existing != null) {
      await txn.update(
        'exercises',
        values,
        where: 'id = ? AND is_custom = 0',
        whereArgs: <Object>[existing],
      );
      _remember(known, name, existing);
      for (final String alias in aliases) {
        _remember(known, alias, existing);
      }
      return existing;
    }
    values['is_custom'] = 0;
    final int id = await txn.insert('exercises', values);
    _remember(known, name, id);
    for (final String alias in aliases) {
      _remember(known, alias, id);
    }
    return id;
  }

  /// Catalog rows the JSON does not mention stay, with a plain strength default.
  Future<void> _markLeftovers(Transaction txn, Set<int> matched) async {
    final List<Map<String, Object?>> rows = await txn.query(
      'exercises',
      columns: <String>['id'],
      where: 'is_custom = 0',
    );
    for (final Map<String, Object?> row in rows) {
      final int id = (row['id'] as num).toInt();
      if (matched.contains(id)) {
        continue;
      }
      await txn.update(
        'exercises',
        <String, Object?>{
          'is_free': 0,
          'type': 'strength',
          'met': 5.0,
        },
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }
  }

  Future<void> _onlyWalkingAndRunningAreFree(Transaction txn) async {
    await txn.execute('''
      UPDATE exercises
      SET is_free = CASE
        WHEN LOWER(name) = 'walking' OR LOWER(name) = 'running' THEN 1
        ELSE 0
      END
      WHERE is_custom = 0
    ''');
  }

  int? _find(Map<String, int> known, String name, List<String> aliases) {
    final int? byName = known[name.toLowerCase()];
    if (byName != null) {
      return byName;
    }
    for (final String alias in aliases) {
      final int? id = known[alias.toLowerCase()];
      if (id != null) {
        return id;
      }
    }
    return null;
  }

  void _remember(Map<String, int> known, String? token, int id) {
    final String? text = _text(token);
    if (text == null) {
      return;
    }
    known.putIfAbsent(text.toLowerCase(), () => id);
  }

  List<String> _aliasList(Object? raw) {
    if (raw is! List<dynamic>) {
      return <String>[];
    }
    final List<String> aliases = <String>[];
    for (final dynamic item in raw) {
      final String? text = _text(item);
      if (text != null && !aliases.contains(text)) {
        aliases.add(text);
      }
    }
    return aliases;
  }

  List<String> _split(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }
    return <String>[
      for (final String part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  String _type(Object? raw) {
    final String? text = _text(raw);
    const List<String> allowed = <String>[
      'duration',
      'strength',
      'bodyweight',
      'timed',
    ];
    if (text != null && allowed.contains(text)) {
      return text;
    }
    return 'strength';
  }

  int _isFreeName(String name) {
    final String lower = name.toLowerCase();
    if (lower == 'walking' || lower == 'running') {
      return 1;
    }
    return 0;
  }

  String? _variantsText(Object? raw) {
    if (raw is! List<dynamic> || raw.isEmpty) {
      return null;
    }
    return jsonEncode(raw);
  }

  String? _text(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final String text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  double? _number(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return null;
  }
}

/// All, then the groups in the saved JSON order, then any extra groups.
List<String> exerciseChips(List<String> found, String? savedOrder) {
  final List<String> chips = <String>['All'];
  final Set<String> used = <String>{'All'};
  if (savedOrder != null && savedOrder.isNotEmpty) {
    final Object? decoded = jsonDecode(savedOrder);
    if (decoded is List<dynamic>) {
      for (final dynamic item in decoded) {
        final String name = item.toString();
        if (found.contains(name) && used.add(name)) {
          chips.add(name);
        }
      }
    }
  }
  final List<String> rest = List<String>.from(found)..sort();
  for (final String name in rest) {
    if (used.add(name)) {
      chips.add(name);
    }
  }
  return chips;
}
