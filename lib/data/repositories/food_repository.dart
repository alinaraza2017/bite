import 'package:sqflite/sqflite.dart';

import '../models/food.dart';
import '../models/food_unit.dart';

// How it works: search is a SQLite match on the name and the aliases.
// Exact matches come first, then names that start with the letters, then the rest.
// The default serving is joined so the list can show the unit and the kcal.

class FoodRepository {
  FoodRepository(this._database);

  final Database _database;

  Future<List<Food>> searchFoods(
    String query, {
    String? category,
    int limit = 50,
  }) async {
    final String text = query.trim().toLowerCase();
    final String whereName = text.isEmpty
        ? '1 = 1'
        : '''
        (
          LOWER(foods.name) LIKE '%' || ? || '%'
          OR LOWER(IFNULL(foods.aliases, '')) LIKE '%' || ? || '%'
        )
        ''';
    final String rank = text.isEmpty
        ? 'foods.name COLLATE NOCASE'
        : '''
        CASE
          WHEN LOWER(foods.name) = ? THEN 0
          WHEN INSTR(',' || LOWER(IFNULL(foods.aliases, '')) || ',', ',' || ? || ',') > 0 THEN 0
          WHEN LOWER(foods.name) LIKE ? || '%' THEN 1
          WHEN INSTR(',' || LOWER(IFNULL(foods.aliases, '')) || ',', ',' || ?) > 0 THEN 1
          ELSE 2
        END,
        foods.name COLLATE NOCASE
        ''';
    final List<Object?> args = <Object?>[];
    if (text.isNotEmpty) {
      args.add(text);
      args.add(text);
    }
    args.add(category);
    args.add(category);
    if (text.isNotEmpty) {
      args.add(text);
      args.add(text);
      args.add(text);
      args.add(text);
    }
    args.add(limit);
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT foods.*, serving_units.label AS unit_label,
             serving_units.calories AS unit_calories
      FROM foods
      LEFT JOIN serving_units
        ON serving_units.food_id = foods.id AND serving_units.is_default = 1
      WHERE $whereName
        AND (? IS NULL OR foods.category = ?)
      ORDER BY $rank
      LIMIT ?
      ''',
      args,
    );
    return rows.map(Food.fromMap).toList();
  }

  /// Every category saved on a food. The screen adds "All" and sorts them.
  Future<List<String>> categories() async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      'SELECT DISTINCT category FROM foods',
    );
    return <String>[
      for (final Map<String, Object?> row in rows) row['category'] as String,
    ];
  }

  Future<Food?> foodById(int id) async {
    final List<Map<String, Object?>> rows = await _database.rawQuery(
      '''
      SELECT foods.*, serving_units.label AS unit_label,
             serving_units.calories AS unit_calories
      FROM foods
      LEFT JOIN serving_units
        ON serving_units.food_id = foods.id AND serving_units.is_default = 1
      WHERE foods.id = ?
      ''',
      <Object>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return Food.fromMap(rows.first);
  }

  Future<List<FoodUnit>> unitsFor(int foodId) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'serving_units',
      where: 'food_id = ?',
      whereArgs: <Object>[foodId],
      orderBy: 'is_default DESC, id ASC',
    );
    return rows.map(FoodUnit.fromMap).toList();
  }

  Future<int> customCount() async {
    final int? count = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM foods WHERE is_custom = 1',
      ),
    );
    return count ?? 0;
  }

  Future<int> addCustomFood({
    required String name,
    required String category,
    required FoodUnitInput unit,
  }) async {
    return _database.transaction((Transaction txn) async {
      final int foodId = await txn.insert('foods', <String, Object?>{
        'name': name.trim(),
        'category': category,
        'is_custom': 1,
        'has_tadka': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.insert('serving_units', <String, Object?>{
        'food_id': foodId,
        'label': unit.label.trim(),
        'grams': unit.grams,
        'is_default': 1,
        'calories': unit.calories,
        'protein': unit.protein,
        'carbs': unit.carbs,
        'fat': unit.fat,
      });
      return foodId;
    });
  }
}
