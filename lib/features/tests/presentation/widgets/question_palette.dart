import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/palette_cell.dart';
import 'player_colors.dart';

/// Horizontal question palette. Tapping a cell jumps to that question.
class QuestionPalette extends StatelessWidget {
  const QuestionPalette({
    super.key,
    required this.cells,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<PaletteCell> cells;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: cells.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          return _PaletteDot(
            cell: cells[index],
            selected: index == currentIndex,
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final PaletteCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = _fillColor(cell.fill);
    final outline = _outlineColor(cell.outline);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: cell.semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        key: Key('palette-${cell.questionNumber}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : (outline ??
                            (fill == null
                                ? colorScheme.outline
                                : Colors.transparent)),
                  width: selected || outline != null ? 2.5 : 1,
                ),
              ),
              child: cell.showGreenCheck
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${cell.questionNumber}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fill == null
                            ? colorScheme.onSurface
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            if (cell.showReviewDot)
              const Positioned(right: -1, top: -1, child: _ReviewDot()),
          ],
        ),
      ),
    );
  }

  static Color? _fillColor(PaletteFill fill) => switch (fill) {
    PaletteFill.grey => PlayerColors.notVisited,
    PaletteFill.red => PlayerColors.incorrect,
    PaletteFill.green => PlayerColors.correct,
    PaletteFill.purple => PlayerColors.review,
    PaletteFill.none => null,
  };

  static Color? _outlineColor(PaletteOutline outline) => switch (outline) {
    PaletteOutline.none => null,
    PaletteOutline.red => PlayerColors.incorrect,
    PaletteOutline.purple => PlayerColors.review,
  };
}

class _ReviewDot extends StatelessWidget {
  const _ReviewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: PlayerColors.review,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
    );
  }
}
