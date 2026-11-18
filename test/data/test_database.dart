import 'dart:io';

import 'package:path/path.dart' as path_tools;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bite/data/db/database_helper.dart';

class TestDatabase {
  TestDatabase(this.database, this.path);

  final Database database;
  final String path;

  Future<void> close() async {
    await database.close();
    for (final String suffix in ['', '-wal', '-shm']) {
      final File file = File('$path$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

var _nextId = 0;

/// Each test gets its own file so rows cannot leak between tests.
Future<TestDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _nextId += 1;
  final String path = path_tools.join(
    Directory.systemTemp.path,
    'bite_${DateTime.now().microsecondsSinceEpoch}_$_nextId.db',
  );
  final Database database = await openDatabase(path);
  await DatabaseHelper.enableForeignKeys(database);
  await DatabaseHelper.createSchema(database);
  return TestDatabase(database, path);
}
