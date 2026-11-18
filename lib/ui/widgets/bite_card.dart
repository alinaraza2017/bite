import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bite_spacing.dart';

// How it works: a cream-page card with a hairline and one soft shadow.
// Padding stays on the 4-point grid.

class BiteSurface extends StatelessWidget {
  const BiteSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(BiteRadius.card),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(BiteSpacing.md),
        child: child,
      ),
    );
  }
}
