import 'feature_gate.dart';

/// Free accounts stop at 10 custom foods. Premium does not.
const int freeCustomFoodLimit = 10;

bool canAddCustomFood({required int currentCount, required bool isPremium}) {
  if (FeatureGate(isPremium: isPremium).canUse(Feature.unlimitedCustomFoods)) {
    return true;
  }
  return currentCount < freeCustomFoodLimit;
}

/// The 30-day chart and older days are the history past the free 7 days.
bool canOpenFullHistory(bool isPremium) {
  return FeatureGate(isPremium: isPremium).canUse(Feature.fullHistory);
}

/// Recipe builder is a premium stub. Free accounts only see the lock.
bool canOpenRecipes(bool isPremium) {
  return FeatureGate(isPremium: isPremium).canUse(Feature.recipeBuilder);
}
