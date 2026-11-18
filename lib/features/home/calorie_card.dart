import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_spacing.dart';
import '../../core/widgets/bite_card.dart';
import '../../data/models/daily_totals.dart';
import '../../domain/nutrition_calc.dart';
import '../../domain/rounding.dart';
import '../../domain/targets_calc.dart';

/// The big calorie number, the three macro bars, and today's net.
class CalorieCard extends StatelessWidget {
  const CalorieCard({
    super.key,
    required this.eaten,
    required this.burned,
    required this.targets,
  });

  final DailyTotals eaten;
  final double burned;
  final DailyTargets? targets;

  @override
  Widget build(BuildContext context) {
    final int eatenKcal = displayKcal(eaten.kcal);
    final int burnedKcal = displayKcal(burned);
    final int net = displayKcal(
      netCalories(eatenKcal: eaten.kcal, burnedKcal: burned),
    );
    final int? target = targets?.calorieTarget;
    final int? left = target == null
        ? null
        : displayKcal(
            remainingCalories(
              targetKcal: target.toDouble(),
              netKcal: netCalories(eatenKcal: eaten.kcal, burnedKcal: burned),
            ),
          );

    return BiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            target == null ? '$eatenKcal kcal eaten' : '$eatenKcal of $target',
            style: AppTextStyles.number,
          ),
          const SizedBox(height: BiteSpacing.xxs),
          Text(
            left == null
                ? 'Set a goal to see what is left.'
                : (left >= 0 ? '$left kcal left' : '${left.abs()} kcal over'),
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: BiteSpacing.md),
          _MacroLine(
            label: 'Protein',
            grams: eaten.protein,
            target: targets?.proteinGrams,
            color: AppColors.protein,
          ),
          const SizedBox(height: BiteSpacing.sm),
          _MacroLine(
            label: 'Carbs',
            grams: eaten.carbs,
            target: targets?.carbGrams,
            color: AppColors.carbs,
          ),
          const SizedBox(height: BiteSpacing.sm),
          _MacroLine(
            label: 'Fat',
            grams: eaten.fat,
            target: targets?.fatGrams,
            color: AppColors.fat,
          ),
          const SizedBox(height: BiteSpacing.md),
          Text(
            'Eaten $eatenKcal  ·  Burned $burnedKcal  ·  Net $net',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({
    required this.label,
    required this.grams,
    required this.target,
    required this.color,
  });

  final String label;
  final double grams;
  final int? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double fraction = 0;
    if (target != null && target! > 0) {
      fraction = grams / target!;
      if (fraction < 0) {
        fraction = 0;
      }
      if (fraction > 1) {
        fraction = 1;
      }
    }
    final String right = target == null
        ? '${grams.round()} g'
        : '${grams.round()} / $target g';
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            const Spacer(),
            Text(right, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: BiteSpacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.track,
            color: color,
          ),
        ),
      ],
    );
  }
}
