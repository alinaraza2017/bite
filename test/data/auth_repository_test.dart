import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bite/data/repositories/auth_repository.dart';

import 'test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sign up then log in, and a wrong password fails', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final db = await openTestDatabase();
    final AuthRepository auth = AuthRepository(preferences, db.database);

    final AuthResult created = await auth.signUp(
      name: 'Ayesha',
      email: 'ayesha@bite.test',
      password: 'secret1',
    );
    expect(created.ok, isTrue);
    expect(auth.currentAccountId(), created.accountId);

    await auth.logOut();
    expect(auth.currentAccountId(), isNull);

    final AuthResult wrong = await auth.logIn(
      email: 'ayesha@bite.test',
      password: 'nope',
    );
    expect(wrong.ok, isFalse);

    final AuthResult again = await auth.logIn(
      email: 'Ayesha@bite.test',
      password: 'secret1',
    );
    expect(again.accountId, created.accountId);

    final AuthResult duplicate = await auth.signUp(
      name: 'Other',
      email: 'ayesha@bite.test',
      password: 'secret1',
    );
    expect(duplicate.error, 'That email is already used.');
    await db.close();
  });
}
