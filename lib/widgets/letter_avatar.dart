import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// One bold letter on a tint that rotates chili, haldi, violet.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({super.key, required this.letter, this.seed = 0});

  final String letter;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final List<Color> tints = <Color>[
      AppColors.chiliTint,
      AppColors.haldiTint,
      AppColors.violetTint,
    ];
    final List<Color> inks = <Color>[
      AppColors.chili,
      AppColors.haldiText,
      AppColors.violet,
    ];
    final int index = seed.abs() % tints.length;
    final String shown = letter.isEmpty ? '?' : letter[0].toUpperCase();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tints[index],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        shown,
        style: AppTextStyles.sectionHeading.copyWith(color: inks[index]),
      ),
    );
  }
}
