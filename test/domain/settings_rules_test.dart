import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/premium_gate.dart';
import 'package:bite/domain/unit_display.dart';

void main() {
  test('free accounts stop at 10 custom foods', () {
    expect(canAddCustomFood(currentCount: 9, isPremium: false), isTrue);
    expect(canAddCustomFood(currentCount: 10, isPremium: false), isFalse);
    expect(canAddCustomFood(currentCount: 10, isPremium: true), isTrue);
  });

  test('full history and recipes stay locked until premium', () {
    expect(canOpenFullHistory(false), isFalse);
    expect(canOpenFullHistory(true), isTrue);
    expect(canOpenRecipes(false), isFalse);
    expect(canOpenRecipes(true), isTrue);
  });

  test('pounds are display only and convert back to kilograms', () {
    expect(weightFromKg(70, WeightUnit.kg), 70);
    expect(weightFromKg(70, WeightUnit.lb), closeTo(154.323583526, 0.0001));
    expect(
      kgFromWeight(weightFromKg(70, WeightUnit.lb), WeightUnit.lb),
      closeTo(70, 0.0001),
    );
    expect(formatWeight(70, WeightUnit.kg), '70.0 kg');
    expect(formatWeight(70, WeightUnit.lb), '154.3 lb');
  });
}
