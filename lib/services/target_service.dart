import '../domain/models.dart';
import '../domain/targets_calc.dart';

// How it works: Mifflin-St Jeor gives BMR, activity scales it to TDEE,
// then the goal shifts that number. The result is rounded to the nearest 10.
// Protein depends on the goal. Fat takes 25% of the target. Carbs take the rest.

/// Daily calorie target from the profile. Always an estimate.
int dailyTargetKcal(UserProfile profile) {
  return targetsFor(profile).calorieTarget;
}

/// Nearest 10, so 1508.5 becomes 1510 and 1504 becomes 1500.
int roundToNearest10(double value) {
  return (value / 10).round() * 10;
}

double bmrFor(UserProfile profile) {
  return calculateBmr(
    sex: profile.sex,
    weightKg: profile.weightKg,
    heightCm: profile.heightCm,
    ageYears: profile.ageYears,
  );
}

double tdeeFor(UserProfile profile) {
  return bmrFor(profile) * profile.activity.factor;
}
