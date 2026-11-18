import 'package:bite/core/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('welcome uses the account name and never Friend', () {
    expect(greetingName('Friend', 'Ayesha Khan'), 'Ayesha');
    expect(greetingName('', 'Ali'), 'Ali');
    expect(greetingName(null, 'friend'), 'there');
    expect(welcomeLine('Ayesha Khan'), 'Welcome, Ayesha Khan');
    expect(welcomeLine('friend'), 'Welcome');
    expect(welcomeLine(''), 'Welcome');
    expect(welcomeLine(null), 'Welcome');
    expect(welcomeComma, ', ');
    expect(avatarLetter('Friend', 'Ayesha'), 'A');
  });
}
