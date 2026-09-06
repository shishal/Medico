import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../utils/soft_keyboard.dart';
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
      return _ComicSelectSheet<T>(
        title: title,
        items: items,
        labelOf: labelOf,
        selected: selected,
        emptyMessage: emptyMessage,
      );
    },
  );
}

class _ComicSelectSheet<T> extends StatefulWidget {
  const _ComicSelectSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.emptyMessage,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final T? selected;
  final String emptyMessage;

  /// Long lists (colleges) get a search box so tapping the field can type.
  static const searchAfterCount = 8;

  @override
  State<_ComicSelectSheet<T>> createState() => _ComicSelectSheetState<T>();
}

class _ComicSelectSheetState<T> extends State<_ComicSelectSheet<T>> {
  final _query = TextEditingController();

  bool get _showSearch =>
      widget.items.length >= _ComicSelectSheet.searchAfterCount;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.items
        : widget.items
              .where((item) => widget.labelOf(item).toLowerCase().contains(q))
              .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
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
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              if (_showSearch) ...[
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: _query,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  // Flutter enables stylus handwriting by default; on API 34+
                  // emulators that can swallow the tap instead of opening IME.
                  stylusHandwritingEnabled: false,
                  onTap: requestSoftKeyboard,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: Text(widget.emptyMessage),
                )
              else if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: Spacing.lg),
                  child: Text('No matches.'),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, i) {
                      final item = visible[i];
                      final selectedNow = widget.selected == item;
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
                                widget.labelOf(item),
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
      ),
    );
  }
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
