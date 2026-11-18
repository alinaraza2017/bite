import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../ui/widgets/bite_press.dart';

// How it works: every main button is a full-width pill, 56 dp tall.
// Primary is chili, secondary is an outline, premium is haldi.

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BitePress(
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.chili,
            foregroundColor: AppColors.card,
            disabledBackgroundColor: AppColors.chiliTint,
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.button.copyWith(color: AppColors.card),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.baingan,
          side: const BorderSide(color: AppColors.baingan, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.button,
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.haldi,
          foregroundColor: AppColors.baingan,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.baingan),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}
