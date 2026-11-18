import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bite/data/repositories/profile_repository.dart';
import 'package:bite/domain/models.dart';
import 'package:bite/features/onboarding/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('changing the profile recalculates targets', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final ProfileProvider provider = ProfileProvider(
      repository: ProfileRepository(preferences, null),
    );

    provider.setProfile(
      const UserProfile(
        sex: Sex.male,
        ageYears: 25,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
      ),
    );

    expect(provider.targets, isNotNull);
    expect(provider.targets!.calorieTarget, 1510);
    expect(provider.targets!.proteinGrams, 112);

    provider.setProfile(
      const UserProfile(
        sex: Sex.male,
        ageYears: 25,
        heightCm: 175,
        weightKg: 80,
        activity: ActivityLevel.moderate,
        goal: Goal.maintain,
      ),
    );

    expect(provider.targets!.proteinGrams, 128);
    expect(provider.targets!.calorieTarget, 2750);
  });
}
