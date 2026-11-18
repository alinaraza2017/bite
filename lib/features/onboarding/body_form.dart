import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models.dart';
import '../../ui/widgets/bite_chip.dart';
import '../../ui/widgets/labeled_field.dart';
import '../../ui/widgets/section_header.dart';

// How it works: one form for setup and for profile edits.
// Age, gender, height, weight, activity, then goal. Each label sits above its box.

class BodyDetailsForm extends StatelessWidget {
  const BodyDetailsForm({
    super.key,
    required this.age,
    required this.height,
    required this.weight,
    required this.sex,
    required this.activity,
    required this.goal,
    required this.onSex,
    required this.onActivity,
    required this.onGoal,
    this.ageError,
    this.heightError,
    this.weightError,
    this.onDark = false,
  });

  final TextEditingController age;
  final TextEditingController height;
  final TextEditingController weight;
  final Sex sex;
  final ActivityLevel activity;
  final Goal goal;
  final ValueChanged<Sex> onSex;
  final ValueChanged<ActivityLevel> onActivity;
  final ValueChanged<Goal> onGoal;
  final String? ageError;
  final String? heightError;
  final String? weightError;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color? heading = onDark ? AppColors.card : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BiteLabeledField(
          controller: age,
          label: 'Age',
          hint: '25',
          suffix: 'years',
          error: ageError,
          keyboardType: TextInputType.number,
          onInk: onDark,
        ),
        SectionHeader(label: 'Gender', color: heading),
        const SizedBox(height: 8),
        for (final Sex option in Sex.values)
          BiteChip(
            label: option.label,
            selected: sex == option,
            onTap: () => onSex(option),
            onInk: onDark,
            wide: true,
          ),
        const SizedBox(height: 8),
        BiteLabeledField(
          controller: height,
          label: 'Height',
          hint: '160',
          suffix: 'cm',
          error: heightError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onInk: onDark,
        ),
        BiteLabeledField(
          controller: weight,
          label: 'Weight',
          hint: '60',
          suffix: 'kg',
          error: weightError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onInk: onDark,
        ),
        SectionHeader(label: 'Activity level', color: heading),
        const SizedBox(height: 8),
        for (final ActivityLevel level in ActivityLevel.values)
          BiteChip(
            label: level.label,
            selected: activity == level,
            onTap: () => onActivity(level),
            onInk: onDark,
            wide: true,
          ),
        const SizedBox(height: 8),
        SectionHeader(label: 'Goal', color: heading),
        const SizedBox(height: 8),
        for (final Goal option in Goal.values)
          BiteChip(
            label: option.label,
            selected: goal == option,
            onTap: () => onGoal(option),
            onInk: onDark,
            wide: true,
          ),
      ],
    );
  }
}
