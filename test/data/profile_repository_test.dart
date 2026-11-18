import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bite/data/repositories/profile_repository.dart';
import 'package:bite/domain/models.dart';

import 'test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load round trip', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TestDatabase db = await openTestDatabase();
    final int accountId = await db.database.insert('accounts', {
      'name': 'Ayesha',
      'email': 'ayesha@bite.test',
      'salt': 'salt',
      'password_hash': 'hash',
      'created_at': '2026-10-27',
    });
    final ProfileRepository repository = ProfileRepository(
      preferences,
      db.database,
    );
    repository.accountId = accountId;
    const UserProfile profile = UserProfile(
      name: 'Ayesha',
      sex: Sex.female,
      ageYears: 30,
      heightCm: 160,
      weightKg: 60,
      activity: ActivityLevel.light,
      goal: Goal.maintain,
    );

    expect(repository.isOnboardingDone(), isFalse);
    expect(await repository.load(), isNull);

    await repository.save(profile);
    await repository.setOnboardingDone(true);

    final ProfileRepository again = ProfileRepository(preferences, db.database);
    again.accountId = accountId;
    final UserProfile? loaded = await again.load();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Ayesha');
    expect(loaded.sex, Sex.female);
    expect(loaded.ageYears, 30);
    expect(loaded.heightCm, 160);
    expect(loaded.weightKg, 60);
    expect(loaded.activity, ActivityLevel.light);
    expect(loaded.goal, Goal.maintain);
    expect(loaded.isPremium, isFalse);
    expect(again.isOnboardingDone(), isTrue);
    await db.close();
  });

  test('premium stays on after a fresh load', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TestDatabase db = await openTestDatabase();
    final int accountId = await db.database.insert('accounts', {
      'name': 'Ayesha',
      'email': 'ayesha@bite.test',
      'salt': 'salt',
      'password_hash': 'hash',
      'created_at': '2026-10-27',
    });
    final ProfileRepository repository = ProfileRepository(
      preferences,
      db.database,
    );
    repository.accountId = accountId;
    await repository.save(
      const UserProfile(
        name: 'Ayesha',
        sex: Sex.female,
        ageYears: 30,
        heightCm: 160,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.maintain,
      ),
    );
    await repository.savePremiumFlag(true);
    await repository.save(
      const UserProfile(
        name: 'Ayesha',
        sex: Sex.female,
        ageYears: 30,
        heightCm: 160,
        weightKg: 60,
        activity: ActivityLevel.light,
        goal: Goal.maintain,
        isPremium: true,
      ),
    );

    final ProfileRepository again = ProfileRepository(preferences, db.database);
    again.accountId = accountId;
    final UserProfile? loaded = await again.load();
    expect(loaded!.isPremium, isTrue);
    expect(preferences.getBool('is_premium'), isTrue);
    await db.close();
  });
}
