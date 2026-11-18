import 'package:flutter/material.dart';

import '../../core/theme/bite_text.dart';

// How it works: a small uppercase label, with an optional action on the right.

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.color,
  });

  final String label;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: color == null
                ? BiteText.eyebrow
                : BiteText.eyebrow.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
