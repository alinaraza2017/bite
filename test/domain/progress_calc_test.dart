import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/progress_calc.dart';

void main() {
  test('streak counts today and stops at a gap', () {
    final DateTime today = DateTime(2026, 10, 26);
    final Set<String> days = {
      '2026-10-26',
      '2026-10-25',
      '2026-10-23',
    };

    expect(currentStreak(daysWithLogs: days, today: today), 2);
  });

  test('streak still counts yesterday when today has no log yet', () {
    final DateTime today = DateTime(2026, 3, 1);
    final Set<String> days = {
      '2026-02-28',
      '2026-02-27',
    };

    expect(currentStreak(daysWithLogs: days, today: today), 2);
  });

  test('streak is zero when today and yesterday are empty', () {
    expect(
      currentStreak(
        daysWithLogs: {'2026-10-20'},
        today: DateTime(2026, 10, 26),
      ),
      0,
    );
    expect(
      currentStreak(daysWithLogs: {}, today: DateTime(2026, 10, 26)),
      0,
    );
  });

  test('weekly average counts quiet days as zero', () {
    final Map<String, DayNutrition> logged = {
      '2026-10-26': const DayNutrition(
        date: '2026-10-26',
        kcal: 2100,
        protein: 140,
      ),
      '2026-10-20': const DayNutrition(
        date: '2026-10-20',
        kcal: 700,
        protein: 0,
      ),
    };
    final List<DayNutrition> week = fillDays(
      end: DateTime(2026, 10, 26),
      dayCount: 7,
      logged: logged,
    );

    expect(week.length, 7);
    final WeeklyAverages averages = weeklyAverages(week);
    expect(averages.calories, closeTo(2800 / 7, 0.001));
    expect(averages.protein, closeTo(140 / 7, 0.001));
  });

  test('weekly average of an empty list is zero', () {
    expect(weeklyAverages(const []).calories, 0);
    expect(weeklyAverages(const []).protein, 0);
  });
}
