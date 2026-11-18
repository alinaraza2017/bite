import 'package:bite/domain/body_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('age, height, and weight stay inside a human range', () {
    expect(validateAge('25'), isNull);
    expect(validateAge('9'), isNotNull);
    expect(validateAge('101'), isNotNull);
    expect(validateHeight('175'), isNull);
    expect(validateHeight('90'), isNotNull);
    expect(validateWeight('70'), isNull);
    expect(validateWeight('20'), isNotNull);
    expect(validateWeight('301'), isNotNull);
  });
}
