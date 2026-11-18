import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// How it works: a small rounded square. The emoji sits on a faint chili wash.

class EmojiTile extends StatelessWidget {
  const EmojiTile({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.chiliAt(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
