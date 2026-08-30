import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'comic_card.dart';

/// Bottom sheet of tappable sticker rows — more reliable than dropdowns,
/// and it actually lets the student change year / college / batch.
Future<T?> showComicSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelOf,
  T? selected,
  String emptyMessage = 'Nothing to pick yet.',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Spacing.md),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: Text(emptyMessage),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final selectedNow = selected == item;
                      return ComicCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        onTap: () => Navigator.pop(context, item),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                labelOf(item),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (selectedNow)
                              const Icon(Icons.check_circle_rounded),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Field that opens [showComicSelectSheet] — used on onboarding and profile.
class ComicSelectField<T> extends StatelessWidget {
  const ComicSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onSelected,
    this.value,
    this.placeholder = 'Tap to choose',
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onSelected;
  final T? value;
  final String placeholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? placeholder : labelOf(value as T);
    return ComicCard(
      semanticLabel: label,
      onTap: !enabled || items.isEmpty
          ? null
          : () async {
              final picked = await showComicSelectSheet<T>(
                context: context,
                title: label,
                items: items,
                labelOf: labelOf,
                selected: value,
              );
              if (picked != null) onSelected(picked);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  items.isEmpty && value == null ? 'Loading…' : text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ],
      ),
    );
  }
}
