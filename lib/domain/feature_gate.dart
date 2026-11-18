// How it works: every lock asks this class. Premium is the flag already
// saved on the profile. There is no second premium switch.

enum Feature {
  allWorkouts,
  customExercises,
  prTracking,
  fullHistory,
  unlimitedCustomFoods,
  recipeBuilder,
  adaptiveTargets,
}

/// Creating a new custom exercise is premium. Existing custom rows stay usable.
const bool customExercisesRequirePremium = true;

/// Free history is a week. Premium trends go back 30 days, and the daily
/// log can open any older day once [Feature.fullHistory] is allowed.
const int freeHistoryDays = 7;
const int premiumTrendDays = 30;

class FeatureGate {
  const FeatureGate({required this.isPremium});

  final bool isPremium;

  bool canUse(Feature feature) {
    if (feature == Feature.customExercises && !customExercisesRequirePremium) {
      return true;
    }
    return isPremium;
  }
}

/// Free accounts log Walking, Running, and exercises they already created.
/// A catalog exercise with isFree false stays locked.
bool canLogExercise({
  required bool isPremium,
  required bool isFree,
  required bool isCustom,
}) {
  if (isCustom) {
    return true;
  }
  if (isFree) {
    return true;
  }
  return FeatureGate(isPremium: isPremium).canUse(Feature.allWorkouts);
}

class PremiumRequired implements Exception {
  const PremiumRequired();
}
