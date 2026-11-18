import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// How it works: pushed screens fade and slide a little.
// Reduced motion shows the next screen at once.

CustomTransitionPage<void> bitePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    child: child,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondary,
      Widget page,
    ) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return page;
      }
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: page,
        ),
      );
    },
  );
}
