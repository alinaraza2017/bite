import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bite_motion.dart';
import 'bite_press.dart';

// How it works: an outline chip fills with ink when it is chosen.
// The colour change takes 200 ms.

class BiteChip extends StatelessWidget {
  const BiteChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onInk = false,
    this.wide = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// True on the dark aubergine pages, so a selected card fills with cream.
  final bool onInk;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Color fill = selected
        ? (onInk ? AppColors.card : AppColors.text)
        : AppColors.clear;
    final Color ink = selected
        ? (onInk ? AppColors.text : AppColors.card)
        : (onInk ? AppColors.card : AppColors.text);
    final Color line = selected ? fill : (onInk ? AppColors.card : AppColors.hairline);
    return BitePress(
      scale: 0.98,
      child: Material(
        color: AppColors.clear,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: still ? Duration.zero : const Duration(milliseconds: 200),
            curve: BiteMotion.enter,
            height: 48,
            width: wide ? double.infinity : null,
            margin: wide ? const EdgeInsets.only(bottom: 8) : null,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(wide ? 16 : 100),
              border: Border.all(color: line),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
