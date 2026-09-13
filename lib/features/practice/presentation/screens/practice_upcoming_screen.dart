import 'package:flutter/material.dart';

import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_mascot.dart';

/// Practice Builder is parked. The tab stays so testers see it is coming.
class PracticeUpcomingScreen extends StatelessWidget {
  const PracticeUpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ComicMascot(
                asset: BrandAssets.mascotStudy,
                size: 120,
                bounce: false,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Upcoming',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Custom MCQ practice is coming soon.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
