import 'package:flutter/material.dart';

import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/staggered_fade.dart';
import '../../domain/catalog_models.dart';

/// Compact year chips with year art inside. Same [year-chip-*] keys as the
/// taller stickers so Home tests still tap `year-chip-p2`.
class YearPickerRow extends StatelessWidget {
  const YearPickerRow({
    super.key,
    required this.phases,
    required this.selectedId,
    required this.onSelect,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.lg),
  });

  final List<MbbsPhase> phases;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: phases.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, i) {
          final phase = phases[i];
          return StaggeredFade(
            index: i,
            child: _YearChip(
              phase: phase,
              selected: phase.id == selectedId,
              fill: StickerFills.yearFill(phase.displayOrder, brightness),
              onTap: () => onSelect(phase.id),
            ),
          );
        },
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.phase,
    required this.selected,
    required this.fill,
    required this.onTap,
  });

  final MbbsPhase phase;
  final bool selected;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 96,
      child: ComicCard(
        key: ValueKey('year-chip-${phase.id}'),
        color: fill,
        padding: const EdgeInsets.all(Spacing.xs),
        semanticLabel: phase.name,
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      BrandAssets.yearArt(
                        code: phase.code,
                        name: phase.name,
                        displayOrder: phase.displayOrder,
                      ),
                      fit: BoxFit.cover,
                    ),
                    if (selected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              phase.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
