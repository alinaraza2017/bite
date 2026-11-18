import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/unit_display.dart';

/// The small flags that are not the body profile: premium and kg/lb.
class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const String premiumKey = 'is_premium';

  /// When Play last said yes or no. An old time is still trusted while offline.
  /// See decideOwned: a missing answer never takes premium away.
  static const String premiumCheckedAtKey = 'premium_checked_at';
  static const String unitKey = 'weight_unit';

  bool loadPremium() {
    return _preferences.getBool(premiumKey) ?? false;
  }

  DateTime? loadPremiumCheckedAt() {
    final int? millis = _preferences.getInt(premiumCheckedAtKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> savePremium(bool value) async {
    await _preferences.setBool(premiumKey, value);
  }

  Future<void> savePremiumCheck({
    required bool isPremium,
    required DateTime checkedAt,
  }) async {
    await _preferences.setBool(premiumKey, isPremium);
    await _preferences.setInt(
      premiumCheckedAtKey,
      checkedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clearPremiumCheckedAt() async {
    await _preferences.remove(premiumCheckedAtKey);
  }

  WeightUnit loadUnit() {
    return WeightUnitLabel.fromName(_preferences.getString(unitKey));
  }

  Future<void> saveUnit(WeightUnit unit) async {
    await _preferences.setString(unitKey, unit.name);
  }

  Future<void> clear() async {
    await _preferences.remove(premiumKey);
    await _preferences.remove(premiumCheckedAtKey);
    await _preferences.remove(unitKey);
  }
}
