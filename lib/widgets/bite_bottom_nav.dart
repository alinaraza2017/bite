import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

// How it works: four words, no icons. The open tab is a chili pill.
// The bar is a fixed 56 dp so it cannot cover the page.

class BiteBottomNav extends StatelessWidget {
  const BiteBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<String> labels = <String>[
    'Home',
    'Food',
    'Workout',
    'Progress',
  ];

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.paddingOf(context).bottom;
    final double gap = inset > 48 ? 16 : inset;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (int index = 0; index < labels.length; index++)
                Expanded(child: _Tab(index: index, shell: navigationShell)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.index, required this.shell});

  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final bool selected = shell.currentIndex == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        shell.goBranch(index, initialLocation: selected);
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.chiliTint : AppColors.card,
            borderRadius: BorderRadius.circular(100),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              BiteBottomNav.labels[index],
              maxLines: 1,
              style: AppTextStyles.body.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.chili : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
