import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// White chip, or a chili pill when it is the chosen serving.
class ServingChip extends StatelessWidget {
  const ServingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.chili : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.chili : AppColors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.card : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light, Medium, or Heavy. Medium is the usual choice.
class TadkaSelector extends StatelessWidget {
  const TadkaSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const List<String> options = <String>['Light', 'Medium', 'Heavy'];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final String option in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: selected == option ? AppColors.chili : AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          option,
                          style: AppTextStyles.button.copyWith(
                            color: selected == option
                                ? AppColors.card
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "Protein 25g" pill. The colour matches the macro.
class MacroTag extends StatelessWidget {
  const MacroTag({
    super.key,
    required this.label,
    required this.grams,
    required this.kind,
  });

  final String label;
  final int grams;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (kind == 'carbs') {
      background = AppColors.haldiTint;
      foreground = AppColors.haldiText;
    } else if (kind == 'fat') {
      background = AppColors.violetTint;
      foreground = AppColors.violet;
    } else {
      background = AppColors.chiliTint;
      foreground = AppColors.chili;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ${grams}g',
        style: AppTextStyles.caption.copyWith(color: foreground),
      ),
    );
  }
}
