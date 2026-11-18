import 'gym_models.dart';
import 'logged_food.dart';

// How it works: one calendar day, using the numbers saved on each row.
// An empty day has no meals, no finished workout, and no weigh-in.

class DayMark {
  const DayMark({this.eatenKcal = 0, this.hasEntry = false});

  final int eatenKcal;
  final bool hasEntry;
}

class DayWorkoutDetail {
  const DayWorkoutDetail({required this.session, required this.sets});

  final WorkoutSummary session;
  final List<SessionSet> sets;
}

class DayDetail {
  const DayDetail({
    required this.day,
    required this.foods,
    required this.workouts,
    required this.weightKg,
    required this.eatenKcal,
    required this.burnedKcal,
  });

  final DateTime day;
  final List<LoggedFood> foods;
  final List<DayWorkoutDetail> workouts;
  final double? weightKg;
  final int eatenKcal;
  final int burnedKcal;

  int get netKcal => eatenKcal - burnedKcal;

  bool get isEmpty => foods.isEmpty && workouts.isEmpty && weightKg == null;

  static DayDetail empty(DateTime day) {
    return DayDetail(
      day: day,
      foods: const <LoggedFood>[],
      workouts: const <DayWorkoutDetail>[],
      weightKg: null,
      eatenKcal: 0,
      burnedKcal: 0,
    );
  }
}
