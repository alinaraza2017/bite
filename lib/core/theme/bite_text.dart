import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One font family, four sizes. Poppins is bundled so this works offline.
class BiteText {
  BiteText._();

  static const String family = 'Poppins';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.text,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.text,
  );

  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.text,
  );

  /// Small caps label above a section. Ink at 60%.
  static final TextStyle eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    height: 1.2,
    color: AppColors.inkMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.muted,
  );

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}
