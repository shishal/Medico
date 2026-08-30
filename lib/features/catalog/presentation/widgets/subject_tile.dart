import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/comic_med_glyph.dart';
import '../../../../core/widgets/coverage_ring.dart';
import '../../../../core/widgets/staggered_fade.dart';
import '../../domain/catalog_models.dart';
import '../../domain/subject_visual.dart';
import '../../../progress/domain/progress_models.dart';

class SubjectStickerGrid extends StatelessWidget {
  const SubjectStickerGrid({
    super.key,
    required this.subjects,
    this.coverage = const [],
  });

  final List<CatalogSubject> subjects;
  final List<SubjectCoverage> coverage;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: Text('No subjects for this year yet.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      itemCount: subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.md,
        crossAxisSpacing: Spacing.md,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, i) {
        final subject = subjects[i];
        return StaggeredFade(
          index: i,
          child: SubjectSticker(subject: subject, coverage: _match(subject)),
        );
      },
    );
  }

  SubjectCoverage? _match(CatalogSubject subject) {
    for (final row in coverage) {
      if (row.id == subject.id) return row;
    }
    return null;
  }
}

class SubjectSticker extends StatelessWidget {
  const SubjectSticker({super.key, required this.subject, this.coverage});

  final CatalogSubject subject;
  final SubjectCoverage? coverage;

  @override
  Widget build(BuildContext context) {
    final fill = StickerFills.subjectFill(
      subject.name,
      Theme.of(context).brightness,
    );
    // Display fraction from server learnt/total — not a client-computed score.
    final total = coverage?.totalLessons ?? 0;
    final learnt = coverage?.learntLessons ?? 0;
    final progress = total == 0 ? 0.0 : learnt / total;

    return ComicCard(
      key: ValueKey('subject-tile-${subject.id}'),
      color: fill,
      semanticLabel: subject.name,
      onTap: () =>
          context.push(AppRoutes.subjectPath(subject.id, subject.name)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ComicMedGlyph(glyph: glyphForSubject(subject.name), size: 40),
              const Spacer(),
              CoverageRing(
                progress: progress,
                size: 36,
                strokeWidth: 4,
                child: Text(
                  total == 0 ? '—' : '$learnt',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            subject.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (total > 0)
            Text(
              '$learnt / $total lessons',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
