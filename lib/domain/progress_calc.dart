// How it works: a logged day is any date that has at least one food row.
// The streak walks backward from today. If today has no log yet, it starts
// at yesterday, so the run does not break until the day is over.
// Weekly averages add the last 7 calendar days and divide by 7, so a day
// with no food counts as zero.

/// One day's eaten calories and protein. Missing days use zero.
class DayNutrition {
  const DayNutrition({
    required this.date,
    required this.kcal,
    required this.protein,
  });

  final String date;
  final double kcal;
  final double protein;
}

/// Averages for the cards. These are not rounded.
class WeeklyAverages {
  const WeeklyAverages({required this.calories, required this.protein});

  final double calories;
  final double protein;

  static const WeeklyAverages zero = WeeklyAverages(calories: 0, protein: 0);
}

/// Same yyyy-MM-dd text the log table stores.
String progressDayKey(DateTime day) {
  final String year = day.year.toString().padLeft(4, '0');
  final String month = day.month.toString().padLeft(2, '0');
  final String date = day.day.toString().padLeft(2, '0');
  return '$year-$month-$date';
}

/// First day of a window that ends on [end] and contains [dayCount] days.
String rangeStartKey(DateTime end, int dayCount) {
  final DateTime last = DateTime(end.year, end.month, end.day);
  final int count = dayCount < 1 ? 1 : dayCount;
  final DateTime start = last.subtract(Duration(days: count - 1));
  return progressDayKey(start);
}

/// Puts a row on every calendar day. Days with no log stay at zero.
List<DayNutrition> fillDays({
  required DateTime end,
  required int dayCount,
  required Map<String, DayNutrition> logged,
}) {
  final DateTime last = DateTime(end.year, end.month, end.day);
  final int count = dayCount < 1 ? 1 : dayCount;
  final List<DayNutrition> days = [];
  for (int ago = count - 1; ago >= 0; ago--) {
    final DateTime day = last.subtract(Duration(days: ago));
    final String key = progressDayKey(day);
    final DayNutrition? found = logged[key];
    days.add(found ?? DayNutrition(date: key, kcal: 0, protein: 0));
  }
  return days;
}

/// Sum divided by the number of days in the list, including zeros.
WeeklyAverages weeklyAverages(List<DayNutrition> days) {
  if (days.isEmpty) {
    return WeeklyAverages.zero;
  }
  double calories = 0;
  double protein = 0;
  for (final DayNutrition day in days) {
    calories += day.kcal;
    protein += day.protein;
  }
  final double count = days.length.toDouble();
  return WeeklyAverages(calories: calories / count, protein: protein / count);
}

/// Consecutive logged days ending today, or ending yesterday if today is empty.
int currentStreak({
  required Set<String> daysWithLogs,
  required DateTime today,
}) {
  DateTime day = DateTime(today.year, today.month, today.day);
  if (!daysWithLogs.contains(progressDayKey(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  int streak = 0;
  while (daysWithLogs.contains(progressDayKey(day))) {
    streak += 1;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
