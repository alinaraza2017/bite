/// One food. Calories live on [defaultCalories] from the default serving.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.isCustom,
    required this.hasTadka,
    required this.tadkaLightKcal,
    required this.tadkaLightFat,
    required this.tadkaHeavyKcal,
    required this.tadkaHeavyFat,
    required this.createdAt,
    this.defaultUnitLabel = '',
    this.defaultCalories = 0,
  });

  final int id;
  final String name;
  final String category;
  final bool isCustom;
  final bool hasTadka;
  final double tadkaLightKcal;
  final double tadkaLightFat;
  final double tadkaHeavyKcal;
  final double tadkaHeavyFat;
  final String createdAt;
  final String defaultUnitLabel;
  final double defaultCalories;

  factory Food.fromMap(Map<String, Object?> map) {
    return Food(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      category: map['category'] as String,
      isCustom: (map['is_custom'] as num).toInt() == 1,
      hasTadka: (map['has_tadka'] as num).toInt() == 1,
      tadkaLightKcal: (map['tadka_light_kcal'] as num?)?.toDouble() ?? 0,
      tadkaLightFat: (map['tadka_light_fat'] as num?)?.toDouble() ?? 0,
      tadkaHeavyKcal: (map['tadka_heavy_kcal'] as num?)?.toDouble() ?? 0,
      tadkaHeavyFat: (map['tadka_heavy_fat'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String,
      defaultUnitLabel: map['unit_label'] as String? ?? '',
      defaultCalories: (map['unit_calories'] as num?)?.toDouble() ?? 0,
    );
  }
}
