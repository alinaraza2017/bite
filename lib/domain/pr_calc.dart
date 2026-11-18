// How it works: Epley estimates a one-rep max from the weight and the reps.
// The best set is the one with the higher estimate. A new set is a PR
// when it beats that number.

/// Epley: weight x (1 + reps / 30). One rep is the weight itself.
double epleyOneRepMax(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) {
    return 0;
  }
  return weightKg * (1 + reps / 30);
}

/// True when the new set beats the saved best. A missing best is also a PR.
bool isPersonalRecord({
  required double weightKg,
  required int reps,
  double? bestOneRepMax,
}) {
  final double next = epleyOneRepMax(weightKg, reps);
  if (next <= 0) {
    return false;
  }
  if (bestOneRepMax == null || bestOneRepMax <= 0) {
    return true;
  }
  return next > bestOneRepMax;
}
