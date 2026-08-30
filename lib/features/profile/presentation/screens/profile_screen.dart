import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/support.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/comic_mascot.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../providers/current_plan_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/academic_editor.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    final result = await ref.read(authRepositoryProvider).signOut();

    if (!mounted) return;

    setState(() => _isSigningOut = false);

    switch (result) {
      case Success():
        context.go(AppRoutes.login);
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(currentPlanProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final name = profileAsync.value?.fullName?.trim();
    final comic = ComicColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh plan',
            onPressed: () => ref.read(userProfileProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          const Center(
            child: ComicMascot(
              asset: BrandAssets.mascotAvatar,
              size: 96,
              bounce: false,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            (name == null || name.isEmpty) ? 'Medico student' : name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          planAsync.when(
            data: (plan) => Text(
              plan == null ? 'Plan: —' : 'Current plan: ${plan.label}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => InlineErrorMessage(
              message: UserFacingError.display(error),
              onRetry: () => ref.read(userProfileProvider.notifier).refresh(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              final expires = profile.planExpiresAt;
              return Text(
                expires == null
                    ? 'No plan expiry set'
                    : 'Stored plan: ${profile.plan.label} · expires ${expires.toLocal()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.lg),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return ComicCard(child: AcademicEditor(profile: profile));
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.lg),
          ComicCard(
            color: Color.alphaBlend(
              StickerFills.mint.withValues(alpha: 0.4),
              comic.sticker,
            ),
            onTap: () => launchUrl(
              Uri.parse(SupportLinks.whatsAppUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_outlined),
                SizedBox(width: Spacing.md),
                Expanded(child: Text('WhatsApp support')),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ComicCard(
            color: Color.alphaBlend(
              StickerFills.peach.withValues(alpha: 0.4),
              comic.sticker,
            ),
            onTap: () => context.go(AppRoutes.upgrade),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium_outlined),
                SizedBox(width: Spacing.md),
                Expanded(child: Text('Compare plans')),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const ComicCard(child: ThemeModeToggleButton()),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: _isSigningOut ? null : _signOut,
            child: _isSigningOut
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
