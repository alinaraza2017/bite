import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/rounding.dart';

void main() {
  test('display kcal rounds to the nearest whole number', () {
    expect(displayKcal(10.4), 10);
    expect(displayKcal(10.5), 11);
    expect(displayKcal(-1.2), -1);
  });

  test('rounding the total once keeps the sum', () {
    // 10.4 + 10.4 = 20.8, which displays as 21.
    // Rounding each part first would display 10 + 10 = 20.
    expect(displayKcal(10.4 + 10.4), 21);
    expect(displayKcal(10.4) + displayKcal(10.4), 20);
  });
}
