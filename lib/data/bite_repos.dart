import 'package:sqflite/sqflite.dart';

import 'repositories/food_repository.dart';
import 'repositories/gym_repository.dart';
import 'repositories/log_repository.dart';

/// The tables the screens read. Created once after the database opens.
class BiteRepos {
  BiteRepos(this.database)
    : foods = FoodRepository(database),
      logs = LogRepository(database),
      workouts = WorkoutRepository(database);

  final Database database;
  final FoodRepository foods;
  final LogRepository logs;
  final WorkoutRepository workouts;
}
