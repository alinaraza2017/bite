import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database.dart';

// How it works: one SQLite file, bite.db. Foreign keys turn on first.
// onCreate builds the tables. Version 4 adds exercise columns and does not
// delete foods, workouts, or sets.
// DatabaseHelper.open uses this same object, so the app does not open two files.

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int version = biteDatabaseVersion;
  static const String fileName = 'bite.db';

  Database? _database;

  Future<Database> open() async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final folder = await getApplicationDocumentsDirectory();
    final String dbPath = join(folder.path, fileName);
    final Database opened = await openDatabase(
      dbPath,
      version: version,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await createBiteSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Phones already on version 3 keep every row. Only a much older
        // file still rebuilds, which is the upgrade those versions used.
        if (oldVersion < 3) {
          await dropBiteTables(db);
          await createBiteSchema(db);
          return;
        }
        if (oldVersion < 4) {
          await upgradeBiteToV4(db);
        }
      },
    );
    _database = opened;
    return opened;
  }
}
