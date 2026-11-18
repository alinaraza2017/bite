import '../core/utils/format_numbers.dart';
import 'progress_calc.dart';

// How it works: the database returns the days that have rows.
// This fills the gaps with zeros so a chart has one bar per day.
// Averages skip the zero days. A day is on target within 10% of the goal.

class ProgressDay {
  const ProgressDay({
    required this.day,
    required this.eatenKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.burnedKcal,
    required this.workouts,
    required this.minutes,
    required this.loggedFood,
  });

  final DateTime day;
  final int eatenKcal;
  final double protein;
  final double carbs;
  final double fat;
  final int burnedKcal;
  final int workouts;
  final int minutes;
  final bool loggedFood;

  int get netKcal => eatenKcal - burnedKcal;
}

class WeightPoint {
  const WeightPoint({required this.day, required this.kg});

  final DateTime day;
  final double kg;
}

class DayTotals {
  const DayTotals({
    this.eatenKcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.burnedKcal = 0,
    this.workouts = 0,
    this.minutes = 0,
    this.loggedFood = false,
  });

  final int eatenKcal;
  final double protein;
  final double carbs;
  final double fat;
  final int burnedKcal;
  final int workouts;
  final int minutes;
  final bool loggedFood;
}

class ProgressReport {
  const ProgressReport({
    required this.days,
    required this.weights,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageCarbs,
    required this.averageFat,
    required this.loggedDays,
    required this.daysOnTarget,
    required this.streak,
    required this.bestStreak,
    required this.proteinHitDays,
    required this.workoutSessions,
    required this.workoutMinutes,
    required this.burnedTotal,
    required this.hasAnyFood,
    required this.hasAnyWorkout,
  });

  final List<ProgressDay> days;
  final List<WeightPoint> weights;
  final int averageCalories;
  final double averageProtein;
  final double averageCarbs;
  final double averageFat;
  final int loggedDays;
  final int daysOnTarget;
  final int streak;
  final int bestStreak;
  final int proteinHitDays;
  final int workoutSessions;
  final int workoutMinutes;
  final int burnedTotal;
  final bool hasAnyFood;
  final bool hasAnyWorkout;

  bool get isEmpty => !hasAnyFood && !hasAnyWorkout;

  static const ProgressReport empty = ProgressReport(
    days: <ProgressDay>[],
    weights: <WeightPoint>[],
    averageCalories: 0,
    averageProtein: 0,
    averageCarbs: 0,
    averageFat: 0,
    loggedDays: 0,
    daysOnTarget: 0,
    streak: 0,
    bestStreak: 0,
    proteinHitDays: 0,
    workoutSessions: 0,
    workoutMinutes: 0,
    burnedTotal: 0,
    hasAnyFood: false,
    hasAnyWorkout: false,
  );
}

/// Inclusive window ending today. [logged] is keyed by yyyy-MM-dd.
ProgressReport buildProgressReport({
  required DateTime today,
  required int dayCount,
  required Map<String, DayTotals> logged,
  required Set<String> allFoodDates,
  required List<WeightPoint> weights,
  required int calorieTarget,
  required double proteinTarget,
  required bool hasAnyFood,
  required bool hasAnyWorkout,
}) {
  final int count = dayCount < 1 ? 1 : dayCount;
  final DateTime end = DateTime(today.year, today.month, today.day);
  final List<ProgressDay> days = <ProgressDay>[];
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  int eaten = 0;
  int loggedDays = 0;
  int onTarget = 0;
  int proteinHits = 0;
  int sessions = 0;
  int minutes = 0;
  int burned = 0;

  for (int ago = count - 1; ago >= 0; ago--) {
    final DateTime day = end.subtract(Duration(days: ago));
    final DayTotals? row = logged[progressDayKey(day)];
    final ProgressDay built = ProgressDay(
      day: day,
      eatenKcal: row?.eatenKcal ?? 0,
      protein: row?.protein ?? 0,
      carbs: row?.carbs ?? 0,
      fat: row?.fat ?? 0,
      burnedKcal: row?.burnedKcal ?? 0,
      workouts: row?.workouts ?? 0,
      minutes: row?.minutes ?? 0,
      loggedFood: row?.loggedFood ?? false,
    );
    days.add(built);
    sessions += built.workouts;
    minutes += built.minutes;
    burned += built.burnedKcal;
    if (!built.loggedFood) {
      continue;
    }
    loggedDays += 1;
    eaten += built.eatenKcal;
    protein += built.protein;
    carbs += built.carbs;
    fat += built.fat;
    if (isOnCalorieTarget(built.eatenKcal, calorieTarget)) {
      onTarget += 1;
    }
    if (proteinTarget > 0 && built.protein + 0.0001 >= proteinTarget) {
      proteinHits += 1;
    }
  }

  final int average = loggedDays == 0 ? 0 : (eaten / loggedDays).round();
  return ProgressReport(
    days: days,
    weights: weights,
    averageCalories: average,
    averageProtein: loggedDays == 0 ? 0 : protein / loggedDays,
    averageCarbs: loggedDays == 0 ? 0 : carbs / loggedDays,
    averageFat: loggedDays == 0 ? 0 : fat / loggedDays,
    loggedDays: loggedDays,
    daysOnTarget: onTarget,
    streak: currentStreak(daysWithLogs: allFoodDates, today: end),
    bestStreak: bestStreak(allFoodDates),
    proteinHitDays: proteinHits,
    workoutSessions: sessions,
    workoutMinutes: minutes,
    burnedTotal: burned,
    hasAnyFood: hasAnyFood,
    hasAnyWorkout: hasAnyWorkout,
  );
}

/// True when eaten is between 90% and 110% of the target, inclusive.
bool isOnCalorieTarget(int eatenKcal, int calorieTarget) {
  if (calorieTarget <= 0 || eatenKcal <= 0) {
    return false;
  }
  final double low = calorieTarget * 0.9;
  final double high = calorieTarget * 1.1;
  return eatenKcal >= low && eatenKcal <= high;
}

/// Longest run of back-to-back logged days, anywhere in the set.
int bestStreak(Set<String> daysWithLogs) {
  if (daysWithLogs.isEmpty) {
    return 0;
  }
  final List<DateTime> days = <DateTime>[];
  for (final String key in daysWithLogs) {
    final DateTime? day = _parseKey(key);
    if (day != null) {
      days.add(day);
    }
  }
  days.sort();
  int best = 1;
  int run = 1;
  for (int index = 1; index < days.length; index++) {
    final int gap = days[index].difference(days[index - 1]).inDays;
    if (gap == 1) {
      run += 1;
      if (run > best) {
        best = run;
      }
    } else if (gap > 1) {
      run = 1;
    }
  }
  return best;
}

DateTime? _parseKey(String key) {
  final List<String> parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

/// One sentence. No advice, just what the numbers show.
String progressInsight({
  required ProgressReport report,
  required DateTime today,
  required double proteinTarget,
}) {
  final String todayKey = progressDayKey(today);
  final bool loggedToday = report.days.any(
    (ProgressDay day) => progressDayKey(day.day) == todayKey && day.loggedFood,
  );
  if (!loggedToday && report.streak > 0) {
    final String word = report.streak == 1 ? 'day' : 'days';
    return 'Log a meal today to keep your ${report.streak}-$word streak.';
  }
  if (report.loggedDays > 0 && proteinTarget > 0 && report.proteinHitDays > 0) {
    return 'You hit your protein target on ${report.proteinHitDays} of ${report.days.length} days.';
  }
  ProgressDay? peak;
  for (final ProgressDay day in report.days) {
    if (peak == null || day.eatenKcal > peak.eatenKcal) {
      peak = day;
    }
  }
  if (peak != null && peak.eatenKcal > 0) {
    return 'Your highest-calorie day was ${weekdayNames[peak.day.weekday - 1]} (${formatNumber(peak.eatenKcal)} kcal).';
  }
  return 'Log a meal today to start a streak.';
}
