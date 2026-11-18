import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/feature_gate.dart';
import 'package:bite/domain/pr_calc.dart';

void main() {
  test('free accounts cannot use premium features', () {
    const FeatureGate free = FeatureGate(isPremium: false);
    const FeatureGate paid = FeatureGate(isPremium: true);
    for (final Feature feature in Feature.values) {
      expect(free.canUse(feature), isFalse);
      expect(paid.canUse(feature), isTrue);
    }
  });

  test('free logging is walking, running, and existing custom exercises', () {
    expect(
      canLogExercise(isPremium: false, isFree: true, isCustom: false),
      isTrue,
    );
    expect(
      canLogExercise(isPremium: false, isFree: false, isCustom: true),
      isTrue,
    );
    expect(
      canLogExercise(isPremium: false, isFree: false, isCustom: false),
      isFalse,
    );
    expect(
      canLogExercise(isPremium: true, isFree: false, isCustom: false),
      isTrue,
    );
  });

  test('Epley one-rep max and a heavier set is a PR', () {
    expect(epleyOneRepMax(60, 8), closeTo(76, 0.001));
    expect(
      isPersonalRecord(weightKg: 60, reps: 8, bestOneRepMax: 70),
      isTrue,
    );
    expect(
      isPersonalRecord(weightKg: 40, reps: 8, bestOneRepMax: 70),
      isFalse,
    );
    expect(epleyOneRepMax(0, 8), 0);
  });
}