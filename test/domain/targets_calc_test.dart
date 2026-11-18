import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/models.dart';
import 'package:bite/domain/targets_calc.dart';

void main() {
  UserProfile profile({
    ActivityLevel activity = ActivityLevel.moderate,
    Goal goal = Goal.maintain,
  }) {
    return UserProfile(
      sex: Sex.male,
      ageYears: 25,
      heightCm: 175,
      weightKg: 70,
      activity: activity,
      goal: goal,
    );
  }

  test('male moderate targets match the worked example', () {
    expect(
      calculateBmr(sex: Sex.male, weightKg: 70, heightCm: 175, ageYears: 25),
      closeTo(1673.75, 0.001),
    );

    final DailyTargets maintain = targetsFor(profile());
    expect(maintain.bmr, closeTo(1673.75, 0.001));
    expect(maintain.calorieTarget, 2590);

    final DailyTargets lose = targetsFor(profile(goal: Goal.lose));
    expect(lose.calorieTarget, 2090);
    expect(lose.proteinGrams, 112);

    final DailyTargets build = targetsFor(profile(goal: Goal.build));
    expect(build.calorieTarget, 2890);
    expect(build.proteinGrams, 140);
  });

  test('sedentary lose rounds to the nearest 10 with no BMR floor', () {
    final DailyTargets result = targetsFor(
      profile(activity: ActivityLevel.sedentary, goal: Goal.lose),
    );
    expect(result.calorieTarget, 1510);
    expect(result.proteinGrams, 112);
  });
}
