import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bite_spacing.dart';
import '../../core/theme/bite_text.dart';

/// A big tappable card. Selected cards use the primary orange.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? AppColors.chili : AppColors.background;
    final Color foreground = selected ? AppColors.background : AppColors.text;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BiteRadius.card),
        side: BorderSide(
          color: selected ? AppColors.chili : AppColors.line,
        ),
      ),
      child: InkWell(
        onTap: () {
          // A light tick confirms the choice without a second colour.
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(BiteRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BiteSpacing.md,
              vertical: BiteSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BiteText.title.copyWith(color: foreground)),
                if (detail != null) ...[
                  const SizedBox(height: BiteSpacing.xxs),
                  Text(
                    detail!,
                    style: BiteText.body.copyWith(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
