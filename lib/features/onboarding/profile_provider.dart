import 'package:flutter/foundation.dart';

import '../../data/repositories/profile_repository.dart';
import '../../domain/models.dart';
import '../../domain/targets_calc.dart';

/// Holds the profile and the targets that come from it.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required ProfileRepository repository,
    UserProfile? initial,
    TargetsCalculator calculator = const TargetsCalculator(),
  }) : _repository = repository,
       _calculator = calculator,
       profile = initial {
    if (profile != null) {
      targets = _calculator.calculate(profile!);
    }
  }

  final ProfileRepository _repository;
  final TargetsCalculator _calculator;

  UserProfile? profile;
  DailyTargets? targets;

  /// Recalculates immediately so step 3 can show the new numbers.
  void setProfile(UserProfile next) {
    profile = next;
    targets = _calculator.calculate(next);
    notifyListeners();
  }

  Future<void> saveAndFinish() async {
    final UserProfile? current = profile;
    if (current == null) {
      throw StateError('Set the profile before finishing onboarding.');
    }
    await _repository.save(current);
    await _repository.setOnboardingDone(true);
  }

  /// Flips the existing premium flag and tells every listening screen at once.
  Future<void> setPremium(bool value) async {
    await _repository.savePremiumFlag(value);
    final UserProfile? current = profile;
    if (current == null) {
      notifyListeners();
      return;
    }
    final UserProfile next = current.copyWith(isPremium: value);
    setProfile(next);
    await _repository.save(next);
  }

  /// Saves an edit without sending the person through onboarding again.
  Future<void> saveProfile() async {
    final UserProfile? current = profile;
    if (current == null) {
      throw StateError('Set the profile before saving.');
    }
    await _repository.save(current);
  }

  Future<void> clearProfile() async {
    profile = null;
    targets = null;
    await _repository.clear();
    notifyListeners();
  }
}
