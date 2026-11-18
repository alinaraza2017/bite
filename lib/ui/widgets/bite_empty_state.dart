import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_spacing.dart';
import 'bite_button.dart';

// How it works: a quiet empty page. One emoji, one sentence, one button.

class BiteEmptyState extends StatelessWidget {
  const BiteEmptyState({
    super.key,
    required this.emoji,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BiteSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.chiliAt(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: BiteSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BiteSpacing.lg),
            BiteButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
