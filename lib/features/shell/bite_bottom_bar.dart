import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// How it works: the bar is a short row pinned under the page.
// A fixed height stops it growing to the full screen and hiding Home.
// The selected word sits in a chili pill. Tapping the open tab shows
// that tab's first screen. Each label is a button, and the tap ticks.

class BiteBottomBar extends StatelessWidget {
  const BiteBottomBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<String> labels = <String>[
    'Home',
    'Food',
    'Workout',
    'Progress',
  ];

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: _bottomGap(context)),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (int index = 0; index < labels.length; index++)
                Expanded(
                  child: _BarLabel(
                    label: labels[index],
                    selected: index == navigationShell.currentIndex,
                    still: still,
                    onTap: () => _go(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Space under the labels so they clear the system navigation bar.
  // Some phones report a bottom inset almost as tall as the screen.
  // Using that number paints a white block and leaves the words in the middle.
  double _bottomGap(BuildContext context) {
    final double reported = MediaQuery.paddingOf(context).bottom;
    if (reported > 48) {
      return 16;
    }
    return reported;
  }

  void _go(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BarLabel extends StatelessWidget {
  const _BarLabel({
    required this.label,
    required this.selected,
    required this.still,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool still;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.body.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      color: selected ? AppColors.chili : AppColors.muted,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        // The parent row is 56 dp tall, so this center stays inside the bar.
        child: Center(
          child: AnimatedContainer(
            duration: still ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.chiliTint : AppColors.card,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(label, maxLines: 1, style: style),
          ),
        ),
      ),
    );
  }
}
