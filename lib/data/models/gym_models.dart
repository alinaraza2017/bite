import 'dart:convert';

/// One pace or style inside an exercise, such as Brisk walking.
class ExerciseVariant {
  const ExerciseVariant({
    required this.label,
    required this.met,
    this.speedKmh,
    this.isDefault = false,
  });

  final String label;
  final double met;
  final double? speedKmh;
  final bool isDefault;

  factory ExerciseVariant.fromMap(Map<String, dynamic> map) {
    final Object? speed = map['speedKmh'];
    return ExerciseVariant(
      label: map['label'] as String? ?? '',
      met: (map['met'] as num?)?.toDouble() ?? 0,
      speedKmh: speed is num ? speed.toDouble() : null,
      isDefault: map['isDefault'] == true,
    );
  }
}

/// One exercise row.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.aliases = '',
    this.emoji = '💪',
    this.type = 'strength',
    this.equipment = '',
    this.met = 5,
    this.isFree = false,
    this.isCustom = false,
    this.variantsJson,
  });

  final int id;
  final String name;
  final String muscleGroup;
  final String aliases;
  final String emoji;
  final String type;
  final String equipment;
  final double met;
  final bool isFree;
  final bool isCustom;
  final String? variantsJson;

  List<ExerciseVariant> get variants {
    final String? raw = variantsJson;
    if (raw == null || raw.isEmpty) {
      return const <ExerciseVariant>[];
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const <ExerciseVariant>[];
    }
    return <ExerciseVariant>[
      for (final dynamic item in decoded)
        if (item is Map<String, dynamic>)
          ExerciseVariant.fromMap(item)
        else if (item is Map)
          ExerciseVariant.fromMap(Map<String, dynamic>.from(item)),
    ];
  }

  /// The pace the catalog marks as the usual one.
  ExerciseVariant? get defaultVariant {
    for (final ExerciseVariant variant in variants) {
      if (variant.isDefault) {
        return variant;
      }
    }
    if (variants.isEmpty) {
      return null;
    }
    return variants.first;
  }

  ExerciseVariant? variantByLabel(String? label) {
    if (label == null || label.isEmpty) {
      return defaultVariant;
    }
    for (final ExerciseVariant variant in variants) {
      if (variant.label == label) {
        return variant;
      }
    }
    return defaultVariant;
  }

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      muscleGroup: map['muscle_group'] as String,
      aliases: map['aliases'] as String? ?? '',
      emoji: (map['emoji'] as String?) ?? '💪',
      type: map['type'] as String? ?? 'strength',
      equipment: map['equipment'] as String? ?? '',
      met: (map['met'] as num?)?.toDouble() ?? 5,
      isFree: (map['is_free'] as num?)?.toInt() == 1,
      isCustom: (map['is_custom'] as num?)?.toInt() == 1,
      variantsJson: map['variants_json'] as String?,
    );
  }
}

/// A named plan such as Upper Body, plus the exercises in order.
class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final int id;
  final String name;
  final List<Exercise> exercises;
}

/// One set inside a session.
class SessionSet {
  const SessionSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.completed,
    this.minutes = 0,
    this.holdSeconds = 0,
    this.variantLabel,
    this.emoji = '💪',
    this.exerciseType = 'strength',
  });

  final int id;
  final int sessionId;
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool completed;
  final int minutes;
  final int holdSeconds;
  final String? variantLabel;
  final String emoji;
  final String exerciseType;

  factory SessionSet.fromMap(Map<String, Object?> map) {
    return SessionSet(
      id: (map['id'] as num).toInt(),
      sessionId: (map['session_id'] as num).toInt(),
      exerciseId: (map['exercise_id'] as num).toInt(),
      exerciseName: map['exercise_name'] as String? ?? '',
      setNumber: (map['set_number'] as num).toInt(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      reps: (map['reps'] as num).toInt(),
      completed: (map['completed'] as num).toInt() == 1,
      minutes: (map['minutes'] as num?)?.toInt() ?? 0,
      holdSeconds: (map['hold_seconds'] as num?)?.toInt() ?? 0,
      variantLabel: map['variant_label'] as String?,
      emoji: map['exercise_emoji'] as String? ?? '💪',
      exerciseType: map['exercise_type'] as String? ?? 'strength',
    );
  }
}

/// The last saved set for an exercise, used to prefill the next one.
class LastSet {
  const LastSet({
    required this.weightKg,
    required this.reps,
    this.minutes = 0,
    this.holdSeconds = 0,
    this.variantLabel,
  });

  final double weightKg;
  final int reps;
  final int minutes;
  final int holdSeconds;
  final String? variantLabel;
}

/// One workout session, finished or still open.
class WorkoutSummary {
  const WorkoutSummary({
    required this.id,
    required this.date,
    required this.name,
    required this.durationMin,
    required this.burnedKcal,
    this.templateId,
    this.endedAt,
    this.startedAt = '',
    this.totalSets = 0,
  });

  final int id;
  final String date;
  final String name;
  final int durationMin;
  final double burnedKcal;
  final int? templateId;
  final String? endedAt;
  final String startedAt;
  final int totalSets;

  bool get isFinished => endedAt != null && endedAt!.isNotEmpty;

  factory WorkoutSummary.fromMap(Map<String, Object?> map) {
    final Object? ended = map['ended_at'];
    final Object? template = map['template_id'];
    return WorkoutSummary(
      id: (map['id'] as num).toInt(),
      date: map['date'] as String,
      name: map['name'] as String,
      durationMin: (map['duration_min'] as num?)?.toInt() ?? 0,
      burnedKcal: (map['est_kcal_burned'] as num?)?.toDouble() ?? 0,
      templateId: template == null ? null : (template as num).toInt(),
      endedAt: ended == null ? null : ended as String,
      startedAt: map['started_at'] as String? ?? '',
      totalSets: (map['total_sets'] as num?)?.toInt() ?? 0,
    );
  }
}
