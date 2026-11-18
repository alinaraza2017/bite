import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/widgets/bite_card.dart';
import 'letter_avatar.dart';

/// A tappable white row: letter, title, caption, and a value on the right.
class ListRowCard extends StatelessWidget {
  const ListRowCard({
    super.key,
    required this.letter,
    required this.title,
    required this.subtitle,
    this.value = '',
    required this.onTap,
    this.seed = 0,
  });

  final String letter;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BiteCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              LetterAvatar(letter: letter, seed: seed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionHeading),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(value, style: AppTextStyles.sectionHeading),
            ],
          ),
        ),
      ),
    );
  }
}
