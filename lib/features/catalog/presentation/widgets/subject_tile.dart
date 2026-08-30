import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/comic_med_glyph.dart';
import '../../../../core/widgets/staggered_fade.dart';
import '../../domain/catalog_models.dart';
import '../../domain/subject_visual.dart';

class SubjectStickerGrid extends StatelessWidget {
  const SubjectStickerGrid({super.key, required this.subjects});

  final List<CatalogSubject> subjects;

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
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final subject = subjects[i];
        return StaggeredFade(
          index: i,
          child: SubjectSticker(subject: subject),
        );
      },
    );
  }
}

class SubjectSticker extends StatelessWidget {
  const SubjectSticker({super.key, required this.subject});

  final CatalogSubject subject;

  @override
  Widget build(BuildContext context) {
    final fill = StickerFills.subjectFill(
      subject.name,
      Theme.of(context).brightness,
    );
    return ComicCard(
      key: ValueKey('subject-tile-${subject.id}'),
      color: fill,
      semanticLabel: subject.name,
      onTap: () =>
          context.push(AppRoutes.subjectPath(subject.id, subject.name)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComicMedGlyph(glyph: glyphForSubject(subject.name), size: 48),
          const Spacer(),
          Text(
            subject.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
