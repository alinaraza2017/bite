// How it works: BMR is Mifflin-St Jeor. TDEE is BMR times the activity factor.
// Lose subtracts 500 and build adds 300. The calorie target rounds to the
// nearest 10. Protein is 1.6 g/kg, or 2.0 g/kg when the goal is build.
// Fat is 25% of that target. Carbs use the kcal that are left.

import 'constants.dart';
import 'models.dart';

/// Mifflin-St Jeor. Male adds 5, female subtracts 161.
double calculateBmr({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int ageYears,
}) {
  final double base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
  if (sex == Sex.male) {
    return base + 5;
  }
  return base - 161;
}

/// Daily calorie and macro targets. Gram fields and the calorie target are whole numbers.
class DailyTargets {
  const DailyTargets({
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbGrams,
  });

  final double bmr;
  final double tdee;
  final int calorieTarget;
  final int proteinGrams;
  final int fatGrams;
  final int carbGrams;
}

DailyTargets targetsFor(UserProfile profile) {
  final double bmr = calculateBmr(
    sex: profile.sex,
    weightKg: profile.weightKg,
    heightCm: profile.heightCm,
    ageYears: profile.ageYears,
  );
  final double tdee = bmr * profile.activity.factor;
  final double shifted = tdee + _goalChange(profile.goal);
  final int calorieTarget = _nearest10(shifted);

  final double proteinPerKg = profile.goal == Goal.build
      ? BiteConstants.proteinGramsPerKgBuild
      : BiteConstants.proteinGramsPerKg;
  final int proteinGrams = (profile.weightKg * proteinPerKg).round();
  final int fatGrams =
      (calorieTarget *
              BiteConstants.fatShareOfCalories /
              BiteConstants.kcalPerGramFat)
          .round();
  final double proteinKcal = proteinGrams * BiteConstants.kcalPerGramProtein;
  final double fatKcal = fatGrams * BiteConstants.kcalPerGramFat;
  final double carbKcal = calorieTarget - proteinKcal - fatKcal;
  final int carbGrams = carbKcal <= 0
      ? 0
      : (carbKcal / BiteConstants.kcalPerGramCarbs).round();

  return DailyTargets(
    bmr: bmr,
    tdee: tdee,
    calorieTarget: calorieTarget,
    proteinGrams: proteinGrams,
    fatGrams: fatGrams,
    carbGrams: carbGrams,
  );
}

int _nearest10(double value) {
  return (value / 10).round() * 10;
}

double _goalChange(Goal goal) {
  switch (goal) {
    case Goal.lose:
      return BiteConstants.loseKcalChange;
    case Goal.maintain:
      return 0;
    case Goal.build:
      return BiteConstants.buildKcalChange;
  }
}

/// Onboarding calls [targetsFor]. The math stays in that function.
class TargetsCalculator {
  const TargetsCalculator();

  DailyTargets calculate(UserProfile profile) {
    return targetsFor(profile);
  }
}
