import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_title.dart';
import '../providers/pending_submit_sync_provider.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/home_test_type_grid.dart';
import '../widgets/home_today_section.dart';
import '../widgets/home_week_strip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingSubmitSyncProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xl),
          children: [
            const HomeGreetingHeader(),
            const HomeWeekStrip(),
            const HomeTodaySection(),
            const AppSectionTitle(
              title: 'Tests',
              subtitle: 'Pick a format and start a session',
            ),
            const HomeTestTypeGrid(),
            const AppSectionTitle(title: 'Saved'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: AppCard(
                color: CategoryTints.at(2, Theme.of(context).brightness),
                onTap: () => context.push(AppRoutes.bookmarks),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_outline_rounded),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        'Bookmarks',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
