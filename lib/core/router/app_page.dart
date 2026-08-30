import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Quiet fade used instead of the default Material slide.
CustomTransitionPage<void> fadeTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

GoRoute fadeGoRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        fadeTransitionPage(state: state, child: builder(context, state)),
  );
}
