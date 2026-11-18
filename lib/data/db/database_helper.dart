import 'package:sqflite/sqflite.dart';

import '../database.dart';
import 'app_database.dart';

// How it works: screens and bootstrap ask DatabaseHelper. The file is opened
// by AppDatabase, which is the one singleton for bite.db.

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const int version = AppDatabase.version;
  static const String fileName = AppDatabase.fileName;

  Future<Database> open() {
    return AppDatabase.instance.open();
  }

  /// Must run outside a transaction. Tests call this before createSchema.
  static Future<void> enableForeignKeys(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> createSchema(Database db) async {
    await createBiteSchema(db);
  }
}
