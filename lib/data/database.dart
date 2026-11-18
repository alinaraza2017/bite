import 'package:sqflite/sqflite.dart';

// How it works: version 2 stores calories on the serving, not per 100 g.
// An older phone drops the old tables once, then this schema is created.
// Logs keep the numbers that were calculated at save time.

const int biteDatabaseVersion = 4;

Future<void> createBiteSchema(Database db) async {
  await db.execute('''
    CREATE TABLE foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      aliases TEXT,
      emoji TEXT,
      kcal100 REAL,
      protein100 REAL,
      carbs100 REAL,
      fat100 REAL,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      is_custom INTEGER NOT NULL DEFAULT 0,
      has_tadka INTEGER NOT NULL DEFAULT 0,
      tadka_light_kcal REAL,
      tadka_light_fat REAL,
      tadka_heavy_kcal REAL,
      tadka_heavy_fat REAL,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE serving_units (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      food_id INTEGER NOT NULL,
      label TEXT NOT NULL,
      grams REAL NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE food_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      meal TEXT NOT NULL,
      food_id INTEGER NOT NULL,
      unit_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      tadka TEXT,
      calories REAL NOT NULL,
      protein REAL NOT NULL,
      carbs REAL NOT NULL,
      fat REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (food_id) REFERENCES foods(id),
      FOREIGN KEY (unit_id) REFERENCES serving_units(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE,
      salt TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE user_profile (
      account_id INTEGER PRIMARY KEY,
      name TEXT,
      sex TEXT,
      age INTEGER,
      height_cm REAL,
      weight_kg REAL,
      activity_level TEXT,
      goal TEXT,
      daily_target_kcal INTEGER,
      units TEXT DEFAULT 'kg·cm',
      is_premium INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      muscle_group TEXT NOT NULL,
      aliases TEXT,
      emoji TEXT,
      type TEXT NOT NULL DEFAULT 'strength',
      equipment TEXT,
      met REAL NOT NULL DEFAULT 5.0,
      is_free INTEGER NOT NULL DEFAULT 0,
      is_custom INTEGER NOT NULL DEFAULT 0,
      variants_json TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE workout_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE workout_template_exercises (
      template_id INTEGER NOT NULL,
      exercise_id INTEGER NOT NULL,
      position INTEGER NOT NULL,
      PRIMARY KEY (template_id, exercise_id),
      FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE,
      FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE workout_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template_id INTEGER,
      name TEXT NOT NULL,
      date TEXT NOT NULL,
      started_at TEXT NOT NULL,
      ended_at TEXT,
      duration_min INTEGER,
      total_sets INTEGER,
      est_kcal_burned REAL,
      FOREIGN KEY (template_id) REFERENCES workout_templates(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE workout_sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      exercise_id INTEGER NOT NULL,
      set_number INTEGER NOT NULL,
      weight_kg REAL NOT NULL,
      reps INTEGER NOT NULL,
      minutes INTEGER NOT NULL DEFAULT 0,
      hold_seconds INTEGER NOT NULL DEFAULT 0,
      variant_label TEXT,
      completed INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
      FOREIGN KEY (exercise_id) REFERENCES exercises(id)
    )
  ''');

  await db.execute(
    'CREATE INDEX idx_food_logs_date ON food_logs(date)',
  );
  await db.execute('CREATE INDEX idx_foods_name ON foods(name)');
  await db.execute('CREATE INDEX idx_foods_category ON foods(category)');
  await db.execute(
    'CREATE INDEX idx_workout_sets_exercise ON workout_sets(exercise_id)',
  );
  await db.execute('CREATE INDEX idx_exercises_name ON exercises(name)');
  await db.execute(
    'CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group)',
  );
  await db.execute('''
    CREATE TABLE IF NOT EXISTS weight_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight_kg REAL NOT NULL,
      logged_at TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_workout_sessions_date ON workout_sessions(date)',
  );
}

/// Old table names from version 1, then the new names, so a retry is safe.
Future<void> dropBiteTables(Database db) async {
  const List<String> names = <String>[
    'SetEntries',
    'Workouts',
    'WeightLogs',
    'LogEntries',
    'FoodUnits',
    'Foods',
    'Exercises',
    'workout_sets',
    'workout_sessions',
    'workout_template_exercises',
    'workout_templates',
    'exercises',
    'food_logs',
    'serving_units',
    'foods',
    'user_profile',
    'accounts',
    'weight_logs',
  ];
  for (final String name in names) {
    await db.execute('DROP TABLE IF EXISTS $name');
  }
}

/// Version 4 adds columns. It does not drop foods, workouts, or sets.
Future<void> upgradeBiteToV4(Database db) async {
  await _addColumn(db, 'exercises', 'aliases', 'TEXT');
  await _addColumn(db, 'exercises', 'emoji', 'TEXT');
  await _addColumn(db, 'exercises', 'type', "TEXT NOT NULL DEFAULT 'strength'");
  await _addColumn(db, 'exercises', 'equipment', 'TEXT');
  await _addColumn(db, 'exercises', 'met', 'REAL NOT NULL DEFAULT 5.0');
  await _addColumn(db, 'exercises', 'is_free', 'INTEGER NOT NULL DEFAULT 0');
  await _addColumn(db, 'exercises', 'is_custom', 'INTEGER NOT NULL DEFAULT 0');
  await _addColumn(db, 'exercises', 'variants_json', 'TEXT');
  await _addColumn(db, 'workout_sets', 'minutes', 'INTEGER NOT NULL DEFAULT 0');
  await _addColumn(db, 'workout_sets', 'hold_seconds', 'INTEGER NOT NULL DEFAULT 0');
  await _addColumn(db, 'workout_sets', 'variant_label', 'TEXT');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name)');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group)',
  );
  await db.execute('''
    CREATE TABLE IF NOT EXISTS weight_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      weight_kg REAL NOT NULL,
      logged_at TEXT NOT NULL
    )
  ''');
}

Future<void> _addColumn(
  Database db,
  String table,
  String name,
  String definition,
) async {
  final List<Map<String, Object?>> info = await db.rawQuery(
    'PRAGMA table_info($table)',
  );
  final bool present = info.any((Map<String, Object?> row) => row['name'] == name);
  if (present) {
    return;
  }
  await db.execute('ALTER TABLE $table ADD COLUMN $name $definition');
}
