import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models.dart';
import '../../domain/targets_calc.dart';
import 'settings_repository.dart';

// How it works: each account has one profile row. The onboarding flag
// is stored per account, so logging out does not finish setup for someone else.

class ProfileRepository {
  ProfileRepository(this._preferences, this._database);

  final SharedPreferences _preferences;
  final Database? _database;

  /// The account that is logged in. Null on the login screen.
  int? accountId;

  static const String onboardingDoneKey = 'onboarding_done';

  String get _doneKey {
    final int? id = accountId;
    if (id == null) {
      return onboardingDoneKey;
    }
    return '${onboardingDoneKey}_$id';
  }

  /// Same premium flag the profile row and the offline billing check already use.
  Future<void> savePremiumFlag(bool value) async {
    await _preferences.setBool(SettingsRepository.premiumKey, value);
  }

  Future<void> save(UserProfile profile) async {
    final Database? database = _database;
    final int? id = accountId;
    final int target = targetsFor(profile).calorieTarget;
    if (database == null || id == null) {
      return;
    }
    await database.insert('user_profile', <String, Object?>{
      'account_id': id,
      'name': profile.name,
      'sex': profile.sex.name,
      'age': profile.ageYears,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'activity_level': profile.activity.name,
      'goal': profile.goal.name,
      'daily_target_kcal': target,
      'units': profile.units,
      'is_premium': profile.isPremium ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> load() async {
    final Database? database = _database;
    final int? id = accountId;
    if (database == null || id == null) {
      return null;
    }
    final List<Map<String, Object?>> rows = await database.query(
      'user_profile',
      where: 'account_id = ?',
      whereArgs: <Object>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    final Map<String, Object?> row = rows.first;
    if (row['sex'] == null || row['goal'] == null) {
      return null;
    }
    return UserProfile(
      name: row['name'] as String? ?? '',
      sex: Sex.values.byName(row['sex'] as String),
      ageYears: (row['age'] as num).toInt(),
      heightCm: (row['height_cm'] as num).toDouble(),
      weightKg: (row['weight_kg'] as num).toDouble(),
      activity: activityFromSavedName(row['activity_level'] as String),
      goal: Goal.fromSavedName(row['goal'] as String),
      units: row['units'] as String? ?? 'kg·cm',
      isPremium: (row['is_premium'] as num?)?.toInt() == 1,
    );
  }

  Future<void> setOnboardingDone(bool done) async {
    await _preferences.setBool(_doneKey, done);
  }

  bool isOnboardingDone() {
    return _preferences.getBool(_doneKey) ?? false;
  }

  Future<void> clear() async {
    final Database? database = _database;
    final int? id = accountId;
    if (database != null && id != null) {
      await database.delete(
        'user_profile',
        where: 'account_id = ?',
        whereArgs: <Object>[id],
      );
    }
    await _preferences.setBool(_doneKey, false);
  }
}
