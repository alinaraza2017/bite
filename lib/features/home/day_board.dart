import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/models/daily_totals.dart';
import '../../data/models/day_detail.dart';
import '../../data/models/logged_food.dart';
import '../../data/repositories/progress_repository.dart';
import '../../domain/progress_calc.dart';

/// Today's food rows, calorie sum, and workout burn.
/// A save pings this so Home does not poll the database.
class DayBoard extends ChangeNotifier {
  DayBoard(this.repos) {
    repos.logs.onChanged = _ping;
    repos.workouts.onChanged = _ping;
    _ping();
  }

  final BiteRepos repos;

  DateTime day = dateOnly(DateTime.now());
  DailyTotals eaten = DailyTotals.zero;
  List<LoggedFood> foods = [];
  double burned = 0;
  Map<String, DayMark> marks = <String, DayMark>{};
  bool ready = false;
  Object? error;

  void _ping() {
    unawaited(reload());
  }

  Future<void> showDay(DateTime next) async {
    day = dateOnly(next);
    await reload();
  }

  Future<void> reload() async {
    final String date = progressDayKey(day);
    try {
      eaten = await repos.logs.totalsForDate(date);
      foods = await repos.logs.foodsForDate(date);
      burned = await repos.workouts.burnedForDate(date);
      final DateTime start = mondayOf(day);
      marks = await ProgressRepository(repos.database).marksBetween(
        progressDayKey(start),
        progressDayKey(start.add(const Duration(days: 6))),
      );
      error = null;
    } catch (loadError) {
      error = loadError;
    }
    ready = true;
    notifyListeners();
  }
}
