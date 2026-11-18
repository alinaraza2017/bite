import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/burn_calc.dart';

void main() {
  test('burn is 210 kcal for each finished session', () {
    expect(caloriesBurned(sessionCount: 1), 210);
    expect(caloriesBurned(sessionCount: 0), 0);
    expect(caloriesBurned(sessionCount: 2), 420);
  });

  test('a negative session count throws', () {
    expect(
      () => caloriesBurned(sessionCount: -1),
      throwsArgumentError,
    );
  });

  // Brisk walking uses the variant MET of 5.0, not the slower base pace.
  test('70 kg walking brisk for 30 min is 175 kcal', () {
    expect(durationBurn(met: 5.0, weightKg: 70, minutes: 30), 175);
  });

  test('70 kg running at 9.7 km/h for 30 min is 343 kcal', () {
    expect(durationBurn(met: 9.8, weightKg: 70, minutes: 30), 343);
    expect(
      estimateDistanceKm(speedKmh: 9.7, minutes: 30),
      closeTo(4.85, 0.001),
    );
  });

  test('70 kg bench press for 4 sets is 56 kcal', () {
    expect(strengthBurn(met: 6.0, weightKg: 70, sets: 4), 56);
  });

  test('zero minutes burns nothing', () {
    expect(durationBurn(met: 5, weightKg: 70, minutes: 0), 0);
  });

  test('a very large duration stays a finite kcal', () {
    final int huge = durationBurn(met: 20, weightKg: 200, minutes: 100000000);
    expect(huge, greaterThan(0));
  });

  test('a missing weight falls back to 70 kg', () {
    expect(resolveBodyWeightKg(logKg: null, profileKg: null), assumedBodyWeightKg);
    expect(
      durationBurn(met: 5, weightKg: resolveBodyWeightKg(), minutes: 30),
      175,
    );
    expect(resolveBodyWeightKg(logKg: 80, profileKg: 60), 80);
    expect(resolveBodyWeightKg(logKg: null, profileKg: 60), 60);
  });
}
