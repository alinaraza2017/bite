import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/bite_repos.dart';
import '../../data/repositories/progress_repository.dart';
import '../../domain/progress_report.dart';

// How it works: food saves and finished workouts ping this board.
// It asks the repository again and tells the screen.

class ProgressBoard extends ChangeNotifier {
  ProgressBoard(this.repos) {
    repos.logs.addOnChanged(_ping);
    repos.workouts.addOnChanged(_ping);
  }

  final BiteRepos repos;
  late final ProgressRepository repository = ProgressRepository(repos.database);

  ProgressReport report = ProgressReport.empty;
  int dayCount = 7;
  int _calorieTarget = 0;
  double _proteinTarget = 0;
  bool ready = false;
  Object? error;

  void _ping() {
    unawaited(reload());
  }

  Future<void> reload({
    int? days,
    int? calorieTarget,
    double? proteinTarget,
  }) async {
    if (days != null) {
      dayCount = days;
    }
    if (calorieTarget != null) {
      _calorieTarget = calorieTarget;
    }
    if (proteinTarget != null) {
      _proteinTarget = proteinTarget;
    }
    try {
      report = await repository.load(
        today: DateTime.now(),
        dayCount: dayCount,
        calorieTarget: _calorieTarget,
        proteinTarget: _proteinTarget,
      );
      error = null;
    } catch (loadError) {
      error = loadError;
    }
    ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    repos.logs.removeOnChanged(_ping);
    repos.workouts.removeOnChanged(_ping);
    super.dispose();
  }
}
