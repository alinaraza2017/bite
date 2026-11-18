// How it works: burned kcal comes from the exercise, not one flat session number.
// Duration uses minutes. Strength and bodyweight use a fixed time per set.
// Timed sets add a rest. The result is rounded to a whole kcal.

import 'constants.dart';

/// ASSUMPTION: one strength or bodyweight set, including rest, lasts 120 seconds.
/// Edit this if the rest between sets should be longer or shorter.
const int secondsPerSet = 120;

/// ASSUMPTION: after a timed effort, the person rests for 60 seconds.
const int restSecondsAfterTimedSet = 60;

/// ASSUMPTION: when there is no weight log and no profile weight, use 70 kg.
const double assumedBodyWeightKg = 70;

double caloriesBurned({required int sessionCount}) {
  if (sessionCount < 0) {
    throw ArgumentError('A workout cannot burn a negative amount.');
  }
  return sessionCount * BiteConstants.kcalPerWorkoutSession.toDouble();
}

/// The gym save path used to call this. New workouts sum [estimateExerciseBurn].
class BurnCalculator {
  const BurnCalculator();

  double estimate({required int sessionCount}) {
    return caloriesBurned(sessionCount: sessionCount);
  }
}

/// Latest weight log wins. Profile weight is next. Missing both uses 70 kg.
double resolveBodyWeightKg({double? logKg, double? profileKg}) {
  if (logKg != null && logKg > 0) {
    return logKg;
  }
  if (profileKg != null && profileKg > 0) {
    return profileKg;
  }
  return assumedBodyWeightKg;
}

/// MET x kg x hours. Hours are the active seconds divided by 3600.
int burnFromActiveSeconds({
  required double met,
  required double weightKg,
  required int activeSeconds,
}) {
  if (met <= 0 || weightKg <= 0 || activeSeconds <= 0) {
    return 0;
  }
  final double kcal = met * weightKg * (activeSeconds / 3600);
  return _wholeKcal(kcal);
}

/// Duration: MET x kg x (minutes / 60). Pass the variant MET when one is chosen.
int durationBurn({
  required double met,
  required double weightKg,
  required int minutes,
}) {
  if (minutes <= 0) {
    return 0;
  }
  return burnFromActiveSeconds(
    met: met,
    weightKg: weightKg,
    activeSeconds: minutes * 60,
  );
}

/// Strength and bodyweight share this. The bar weight is not part of the MET.
int strengthBurn({
  required double met,
  required double weightKg,
  required int sets,
}) {
  if (sets <= 0) {
    return 0;
  }
  return burnFromActiveSeconds(
    met: met,
    weightKg: weightKg,
    activeSeconds: sets * secondsPerSet,
  );
}

/// Timed: each set counts its seconds plus the rest that follows.
int timedBurn({
  required double met,
  required double weightKg,
  required int sets,
  required int seconds,
}) {
  if (sets <= 0) {
    return 0;
  }
  final int each = seconds < 0 ? 0 : seconds;
  return burnFromActiveSeconds(
    met: met,
    weightKg: weightKg,
    activeSeconds: sets * (each + restSecondsAfterTimedSet),
  );
}

/// One entry. [type] is duration, strength, bodyweight, or timed.
int estimateExerciseBurn({
  required String type,
  required double met,
  required double weightKg,
  int minutes = 0,
  int sets = 0,
  int seconds = 0,
}) {
  switch (type) {
    case 'duration':
      return durationBurn(met: met, weightKg: weightKg, minutes: minutes);
    case 'timed':
      return timedBurn(
        met: met,
        weightKg: weightKg,
        sets: sets,
        seconds: seconds,
      );
    case 'bodyweight':
    case 'strength':
      return strengthBurn(met: met, weightKg: weightKg, sets: sets);
    default:
      return strengthBurn(met: met, weightKg: weightKg, sets: sets);
  }
}

/// speed x hours. Null when the variant has no speed or the minutes are 0.
double? estimateDistanceKm({double? speedKmh, required int minutes}) {
  if (speedKmh == null || speedKmh <= 0 || minutes <= 0) {
    return null;
  }
  return speedKmh * minutes / 60;
}

int _wholeKcal(double kcal) {
  if (kcal.isNaN || kcal.isInfinite || kcal <= 0) {
    return 0;
  }
  return kcal.round();
}
