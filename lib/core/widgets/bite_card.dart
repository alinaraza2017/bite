import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/bite_spacing.dart';

/// White card. Soft shadow, no border, 16 px corners.
class BiteCard extends StatelessWidget {
  const BiteCard({super.key, required this.child, this.padding});

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
