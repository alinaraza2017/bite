/// Calculations keep full precision. Round to the nearest kcal only on screen.
/// Round the total once. Do not round each macro and then add those results.
int displayKcal(double kcal) {
  return kcal.round();
}
