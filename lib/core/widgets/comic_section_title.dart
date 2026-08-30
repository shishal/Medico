import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Notebook-highlighter heading used on the home sticker sheet.
class ComicSectionTitle extends StatelessWidget {
  const ComicSectionTitle({
    super.key,
    required this.text,
    required this.highlight,
  });

  final String text;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            Positioned(
              left: -4,
              right: -4,
              bottom: 3,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
