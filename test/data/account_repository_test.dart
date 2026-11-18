import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/repositories/account_repository.dart';

import '../data/test_database.dart';

void main() {
  test('export JSON contains the expected keys', () async {
    final TestDatabase db = await openTestDatabase();
    final AccountRepository account = AccountRepository(db.database);

    final String json = await account.exportJson(
      profile: {'weightKg': 70},
      weightUnit: 'kg',
      isPremium: false,
    );
    final Map<String, dynamic> data =
        jsonDecode(json) as Map<String, dynamic>;

    expect(data.keys, containsAll([
      'profile',
      'foods',
      'foodUnits',
      'logs',
      'exercises',
      'workouts',
      'sets',
      'weights',
      'settings',
    ]));
    expect(data['profile'], {'weightKg': 70});
    final Map<String, dynamic> settings =
        data['settings'] as Map<String, dynamic>;
    expect(settings['weightUnit'], 'kg');
    expect(settings['isPremium'], false);
    expect(data['weights'], isA<List<Object?>>());
    expect((data['weights']! as List<Object?>), isEmpty);

    await db.close();
  });
}
