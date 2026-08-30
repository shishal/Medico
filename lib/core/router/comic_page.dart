import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared “comic pop” transition: fade + slight scale + a short slide.
///
/// Used for catalog / onboarding / profile so year → subject → topic feels
/// like flipping sticker pages, not a default Material slide.
CustomTransitionPage<void> comicTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final outgoing = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.72).animate(outgoing),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.07, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

GoRoute comicGoRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        comicTransitionPage(state: state, child: builder(context, state)),
  );
}
