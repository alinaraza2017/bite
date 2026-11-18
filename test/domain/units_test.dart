import 'package:flutter_test/flutter_test.dart';

import 'package:bite/domain/units.dart';

void main() {
  test('grams are unit weight times quantity', () {
    expect(gramsFromUnit(40, 2), 80);
    expect(gramsFromUnit(40, 0), 0);
    expect(gramsFromUnit(40, 0.5), 20);
    expect(gramsFromUnit(100, 10000), 1000000);
  });
}
