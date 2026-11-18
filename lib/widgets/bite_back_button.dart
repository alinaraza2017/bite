import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../ui/widgets/bite_press.dart';

// How it works: one circle for every back action. It hides when this
// route cannot pop, unless the screen passed its own action.
// The system back gesture is left alone.

class BiteBackButton extends StatelessWidget {
  const BiteBackButton({
    super.key,
    this.onPressed,
    this.light = false,
    this.close = false,
  });

  final VoidCallback? onPressed;

  /// Cream icon for the dark aubergine screens.
  final bool light;

  /// X instead of a chevron. Used on sheets.
  final bool close;

  static bool routeCanPop(BuildContext context) {
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      return router.canPop();
    }
    return Navigator.of(context).canPop();
  }

  static void leavePage(BuildContext context) {
    if (routeCanPop(context)) {
      final GoRouter? router = GoRouter.maybeOf(context);
      if (router != null) {
        router.pop();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool show = onPressed != null || routeCanPop(context);
    if (!show) {
      return const SizedBox.shrink();
    }
    final String label = close ? 'Close' : 'Back';
    final Color fill = light ? AppColors.card.withValues(alpha: 0.14) : AppColors.card;
    final Color ink = light ? AppColors.card : AppColors.text;
    final Color line = light ? AppColors.card.withValues(alpha: 0.55) : AppColors.hairline;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: BitePress(
          scale: 0.95,
          child: Material(
            color: fill,
            shape: CircleBorder(side: BorderSide(color: line)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                if (onPressed != null) {
                  onPressed!();
                  return;
                }
                leavePage(context);
              },
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  close ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
