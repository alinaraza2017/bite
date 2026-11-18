import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/progress_report.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 28);

  test('missing days are filled and averages skip empty days', () {
    final ProgressReport report = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-26': const DayTotals(
          eatenKcal: 100,
          protein: 10,
          carbs: 20,
          fat: 5,
          loggedFood: true,
        ),
        '2026-10-27': const DayTotals(
          eatenKcal: 200,
          protein: 20,
          carbs: 40,
          fat: 10,
          loggedFood: true,
        ),
        '2026-10-28': const DayTotals(
          eatenKcal: 300,
          protein: 30,
          carbs: 60,
          fat: 15,
          loggedFood: true,
        ),
      },
      allFoodDates: <String>{'2026-10-26', '2026-10-27', '2026-10-28'},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 40,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );

    expect(report.days, hasLength(7));
    expect(report.days.first.day, DateTime(2026, 10, 22));
    expect(report.days.first.eatenKcal, 0);
    expect(report.days.first.loggedFood, isFalse);
    expect(report.loggedDays, 3);
    expect(report.averageCalories, 200);
    expect(report.averageProtein, 20);
    expect(report.isEmpty, isFalse);
  });

  test('a workout-only day does not count as a logged food day', () {
    final ProgressReport report = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-28': const DayTotals(
          burnedKcal: 180,
          workouts: 1,
          minutes: 40,
        ),
      },
      allFoodDates: <String>{},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 100,
      hasAnyFood: false,
      hasAnyWorkout: true,
    );

    expect(report.loggedDays, 0);
    expect(report.averageCalories, 0);
    expect(report.workoutSessions, 1);
    expect(report.workoutMinutes, 40);
    expect(report.burnedTotal, 180);
    expect(report.days.last.netKcal, -180);
    expect(report.isEmpty, isFalse);
  });

  test('days on target include the 10 percent edges and reject the outside', () {
    expect(isOnCalorieTarget(1890, 2100), isTrue);
    expect(isOnCalorieTarget(1889, 2100), isFalse);
    expect(isOnCalorieTarget(2310, 2100), isTrue);
    expect(isOnCalorieTarget(2311, 2100), isFalse);
    expect(isOnCalorieTarget(0, 2100), isFalse);
    expect(isOnCalorieTarget(2100, 0), isFalse);

    final ProgressReport report = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-26': const DayTotals(eatenKcal: 1890, loggedFood: true),
        '2026-10-27': const DayTotals(eatenKcal: 1889, loggedFood: true),
        '2026-10-28': const DayTotals(eatenKcal: 2310, loggedFood: true),
      },
      allFoodDates: <String>{'2026-10-26', '2026-10-27', '2026-10-28'},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 0,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
    expect(report.daysOnTarget, 2);
  });

  test('streak counts up to today and best streak is the longest run', () {
    expect(
      bestStreak(<String>{
        '2026-10-01',
        '2026-10-02',
        '2026-10-03',
        '2026-10-05',
        '2026-10-06',
      }),
      3,
    );
    expect(bestStreak(<String>{}), 0);

    final ProgressReport report = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-28': const DayTotals(eatenKcal: 1800, loggedFood: true),
        '2026-10-27': const DayTotals(eatenKcal: 1800, loggedFood: true),
      },
      allFoodDates: <String>{
        '2026-10-01',
        '2026-10-02',
        '2026-10-03',
        '2026-10-27',
        '2026-10-28',
      },
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 0,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
    expect(report.streak, 2);
    expect(report.bestStreak, 3);
  });

  test('insight prefers the open streak, then protein, then the peak day', () {
    final ProgressReport openStreak = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-27': const DayTotals(
          eatenKcal: 1800,
          protein: 120,
          loggedFood: true,
        ),
      },
      allFoodDates: <String>{'2026-10-27'},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 100,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
    expect(
      progressInsight(report: openStreak, today: today, proteinTarget: 100),
      'Log a meal today to keep your 1-day streak.',
    );

    final ProgressReport protein = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-28': const DayTotals(
          eatenKcal: 1800,
          protein: 120,
          loggedFood: true,
        ),
      },
      allFoodDates: <String>{'2026-10-28'},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 100,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
    expect(
      progressInsight(report: protein, today: today, proteinTarget: 100),
      'You hit your protein target on 1 of 7 days.',
    );

    final ProgressReport peak = buildProgressReport(
      today: today,
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-24': const DayTotals(eatenKcal: 2640, protein: 10, loggedFood: true),
        '2026-10-28': const DayTotals(eatenKcal: 1500, protein: 10, loggedFood: true),
      },
      allFoodDates: <String>{'2026-10-24', '2026-10-28'},
      weights: const <WeightPoint>[],
      calorieTarget: 2100,
      proteinTarget: 100,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
    expect(
      progressInsight(report: peak, today: today, proteinTarget: 100),
      'Your highest-calorie day was Saturday (2,640 kcal).',
    );
  });
}
