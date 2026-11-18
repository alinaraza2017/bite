export '../core/theme/bite_theme.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Dark screens fade deep, then purple, then plum.
const LinearGradient darkScreenGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    AppColors.baingan,
    AppColors.screenGradientMid,
    AppColors.screenGradientEnd,
  ],
);

const LinearGradient darkCardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[AppColors.baingan, AppColors.cardGradientEnd],
);

const LinearGradient chiliHaldiGradient = LinearGradient(
  colors: <Color>[AppColors.chili, AppColors.haldi],
);

const LinearGradient workoutCardGradient = LinearGradient(
  colors: <Color>[AppColors.chili, AppColors.workoutGradientEnd],
);
