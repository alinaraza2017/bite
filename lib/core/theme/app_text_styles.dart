import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Poppins styles for the new screens. The font files are bundled.
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Poppins';

  static const TextStyle appHeading = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle heading = appHeading;

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  static const TextStyle number = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.text,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle numberLarge = TextStyle(
    fontFamily: family,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.05,
    color: AppColors.text,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static final TextStyle eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.inkMuted,
  );
}
