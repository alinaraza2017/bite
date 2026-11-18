import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'bite_press.dart';

// How it works: the main button is a full pill, 56 dp tall.
// A press scales it slightly and ticks the haptic motor.

class BiteButton extends StatelessWidget {
  const BiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: AppColors.chili,
            foregroundColor: AppColors.card,
            disabledBackgroundColor: AppColors.chiliTint,
            disabledForegroundColor: AppColors.text,
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.button.copyWith(color: AppColors.card),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: BorderSide(color: AppColors.hairline),
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.button,
          );
    final VoidCallback? tap = onPressed == null ? null : _tap;
    final Widget button = filled
        ? FilledButton(onPressed: tap, style: style, child: _label())
        : OutlinedButton(onPressed: tap, style: style, child: _label());
    return BitePress(
      child: SizedBox(
        height: 56,
        width: fullWidth ? double.infinity : null,
        child: button,
      ),
    );
  }

  void _tap() {
    final VoidCallback? action = onPressed;
    if (action == null) {
      return;
    }
    HapticFeedback.lightImpact();
    action();
  }

  Widget _label() {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(label));
  }
}
