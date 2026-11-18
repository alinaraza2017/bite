/// Display conversion only. The database always stores kilograms.
const double poundsPerKilogram = 2.2046226218;

enum WeightUnit { kg, lb }

extension WeightUnitLabel on WeightUnit {
  String get label => this == WeightUnit.kg ? 'kg' : 'lb';

  static WeightUnit fromName(String? name) {
    if (name == 'lb') {
      return WeightUnit.lb;
    }
    return WeightUnit.kg;
  }
}

/// Kilograms shown in the unit the person picked.
double weightFromKg(double kg, WeightUnit unit) {
  if (unit == WeightUnit.kg) {
    return kg;
  }
  return kg * poundsPerKilogram;
}

/// A number the person saw, turned back into stored kilograms.
double kgFromWeight(double shown, WeightUnit unit) {
  if (unit == WeightUnit.kg) {
    return shown;
  }
  return shown / poundsPerKilogram;
}

/// One decimal, plus the unit. Rounding happens here, not in the save.
String formatWeight(double kg, WeightUnit unit) {
  final String number = weightFromKg(kg, unit).toStringAsFixed(1);
  return '$number ${unit.label}';
}
