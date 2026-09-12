import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/brand_pulse_loader.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../providers/auth_session_provider.dart';

/// Brief branded splash; navigates to login or home based on auth session.
///
/// The ECG-M stays screen-center so it lines up with the native launch image
/// from flutter_native_splash. Docci and the wordmark fade in around it.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _markScale;
  late final Animation<double> _copyOpacity;
  late final Animation<double> _mascotOpacity;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _markScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _copyOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.28, 0.7, curve: Curves.easeOut),
    );
    _mascotOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.38, 0.9, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateAway());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _navigateAway() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    final isAuthenticated = ref.read(authSessionProvider);
    context.go(isAuthenticated ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    const onCanvas = Colors.white;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.splashCanvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.12),
            radius: 1.15,
            colors: [
              Color(0xFF2A2422),
              AppTheme.splashCanvas,
              Color(0xFF0A0A0A),
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: const Alignment(0, -0.42),
                    child: Opacity(
                      opacity: _mascotOpacity.value,
                      child: const ComicMascot(
                        asset: BrandAssets.mascotWave,
                        size: 128,
                        heroTag: BrandAssets.mascotHeroTag,
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.scale(
                      scale: _markScale.value,
                      child: const BrandMark(size: 88),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.38),
                    child: Opacity(
                      opacity: _copyOpacity.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Medico',
                            style: textTheme.headlineMedium?.copyWith(
                              color: onCanvas,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'KUHS exam companion',
                            style: textTheme.bodyLarge?.copyWith(
                              color: onCanvas.withValues(alpha: 0.82),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: Spacing.lg),
                          const BrandPulseLoader(color: onCanvas),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
