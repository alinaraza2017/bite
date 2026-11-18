/// Sex values Mifflin-St Jeor knows.
enum Sex {
  male('Male'),
  female('Female');

  const Sex(this.label);

  final String label;
}

/// Four activity levels. The factor is the usual multiplier for that level.
enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Mostly sitting, little exercise.'),
  light(1.375, 'Light', 'Light exercise a few days a week.'),
  moderate(1.55, 'Moderate', 'Exercise most days of the week.'),
  active(1.725, 'Active', 'Hard training or a physical job.');

  const ActivityLevel(this.factor, this.label, this.description);

  final double factor;
  final String label;
  final String description;
}

/// What the person wants the calorie target to do.
enum Goal {
  lose('Lose fat'),
  maintain('Maintain weight'),
  build('Build muscle');

  const Goal(this.label);

  final String label;

  /// Older saves used "gain" for build and "veryActive" is handled on activity.
  static Goal fromSavedName(String name) {
    if (name == 'gain') {
      return Goal.build;
    }
    return Goal.values.byName(name);
  }
}

/// Saved activity names from older builds.
ActivityLevel activityFromSavedName(String name) {
  if (name == 'veryActive') {
    return ActivityLevel.active;
  }
  return ActivityLevel.values.byName(name);
}

/// How oily the tadka was. Medium is the food's base numbers.
enum TadkaLevel { light, medium, heavy }

/// The profile saved on the phone.
class UserProfile {
  const UserProfile({
    this.name = '',
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.units = 'kg·cm',
    this.isPremium = false,
  });

  final String name;
  final Sex sex;
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;
  final String units;
  final bool isPremium;

  /// First letter for the round avatar. Empty name uses "B".
  String get initial {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'B';
    }
    return trimmed[0].toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? ageYears,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    Goal? goal,
    String? units,
    bool? isPremium,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      units: units ?? this.units,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'sex': sex.name,
      'ageYears': ageYears,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activity': activity.name,
      'goal': goal.name,
      'units': units,
      'isPremium': isPremium,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      sex: Sex.values.byName(json['sex'] as String),
      ageYears: (json['ageYears'] as num).toInt(),
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      activity: activityFromSavedName(json['activity'] as String),
      goal: Goal.fromSavedName(json['goal'] as String),
      units: json['units'] as String? ?? 'kg·cm',
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}

/// One set of kcal and grams. [sum] adds a list, including an empty one.
class Macros {
  const Macros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const Macros zero = Macros(kcal: 0, protein: 0, carbs: 0, fat: 0);

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  Macros operator +(Macros other) {
    return Macros(
      kcal: kcal + other.kcal,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }

  static Macros sum(List<Macros> items) {
    Macros total = Macros.zero;
    for (final Macros item in items) {
      total = total + item;
    }
    return total;
  }
}
