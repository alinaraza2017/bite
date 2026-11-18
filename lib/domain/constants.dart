/// Formula numbers that are not written on a food row.
class BiteConstants {
  BiteConstants._();

  /// Energy in one gram. These are the usual 4 / 4 / 9 figures.
  static const double kcalPerGramProtein = 4;
  static const double kcalPerGramCarbs = 4;
  static const double kcalPerGramFat = 9;

  /// ASSUMPTION: a lose goal is 500 kcal under maintenance.
  static const double loseKcalChange = -500;

  /// ASSUMPTION: a build goal is 300 kcal over maintenance.
  static const double buildKcalChange = 300;

  /// Maintain and lose use 1.6 g per kg. Build muscle uses 2.0.
  static const double proteinGramsPerKg = 1.6;
  static const double proteinGramsPerKgBuild = 2.0;

  /// Fat is 25% of the calorie target.
  static const double fatShareOfCalories = 0.25;

  /// One finished workout. The same number is used everywhere.
  static const int kcalPerWorkoutSession = 210;

  /// ASSUMPTION: a week of training is 5 sessions.
  static const int weeklyWorkoutTarget = 5;
}
