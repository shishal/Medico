import 'package:flutter/material.dart';

import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/staggered_fade.dart';
import '../../domain/catalog_models.dart';

/// Horizontal year stickers. The parent owns selection so Home can browse,
/// onboarding can save, and Profile can edit — all with the same control.
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
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: phases.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, i) {
          final phase = phases[i];
          return StaggeredFade(
            index: i,
            child: _YearSticker(
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

class _YearSticker extends StatelessWidget {
  const _YearSticker({
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
    return SizedBox(
      width: 132,
      child: ComicCard(
        key: ValueKey('year-chip-${phase.id}'),
        color: fill,
        padding: const EdgeInsets.all(Spacing.sm),
        semanticLabel: phase.name,
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        BrandAssets.yearArt(
                          code: phase.code,
                          name: phase.name,
                          displayOrder: phase.displayOrder,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(Icons.check_circle, size: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              phase.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
