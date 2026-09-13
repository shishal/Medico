import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/markdown_copy.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../bookmarks/presentation/widgets/bookmark_icon_button.dart';
import '../../../security/domain/capture_event.dart';
import '../../../security/presentation/widgets/content_capture_guard.dart';
import '../../data/pyq_repository.dart';
import '../../domain/pyq_models.dart';
import '../providers/preferred_textbook_provider.dart';
import '../providers/pyq_providers.dart';

enum _ReaderPanel { none, explanation, directAnswer }

class PyqReaderScreen extends ConsumerWidget {
  const PyqReaderScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(pyqDetailProvider(questionId));
    return ContentCaptureGuard(
      screen: ContentScreens.pyqReader,
      child: detail.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('PYQ')),
          body: const AsyncLoadingView(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('PYQ')),
          body: AsyncErrorView(
            message: UserFacingError.display(e),
            onAction: () => ref.invalidate(pyqDetailProvider(questionId)),
          ),
        ),
        data: (value) => _PyqBody(detail: value, questionId: questionId),
      ),
    );
  }
}

class _PyqBody extends ConsumerStatefulWidget {
  const _PyqBody({required this.detail, required this.questionId});

  final PyqDetail detail;
  final String questionId;

  @override
  ConsumerState<_PyqBody> createState() => _PyqBodyState();
}

class _PyqBodyState extends ConsumerState<_PyqBody> {
  // DA (direct answer) is open on first view; EX stays collapsed until tapped.
  _ReaderPanel _panel = _ReaderPanel.directAnswer;
  late bool _learnt;

  @override
  void initState() {
    super.initState();
    _learnt = widget.detail.questionLearnt;
  }

  void _toggle(_ReaderPanel next) {
    setState(() {
      _panel = _panel == next ? _ReaderPanel.none : next;
    });
  }

  Future<void> _openLink(ResourceLink link, PlanTier plan) async {
    if (!link.isFree && plan.rank < PlanTier.pro.rank) {
      if (!mounted) return;
      context.push(AppRoutes.upgradePath(PlanTier.pro));
      return;
    }
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
    final years = d.appearances
        .map((a) => '${a.year} ${a.paperName}')
        .join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('PYQ'),
        actions: [BookmarkIconButton(questionId: widget.questionId)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Row(
            children: [
              _PanelButton(
                label: 'EX',
                selected: _panel == _ReaderPanel.explanation,
                onPressed: () => _toggle(_ReaderPanel.explanation),
              ),
              const SizedBox(width: Spacing.sm),
              _PanelButton(
                label: 'DA',
                selected: _panel == _ReaderPanel.directAnswer,
                onPressed: () => _toggle(_ReaderPanel.directAnswer),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ComicCard(
            color: Color.alphaBlend(
              StickerFills.peach.withValues(alpha: 0.35),
              ComicColors.of(context).sticker,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.teaser.format.label +
                      (d.teaser.marks != null
                          ? ' · ${d.teaser.marks} marks'
                          : '') +
                      ' · ${d.teaser.difficulty.label}' +
                      (d.teaser.appearanceCount > 0
                          ? ' · ${d.teaser.appearanceCount}×'
                          : ''),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  d.teaser.questionText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (years.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(years, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (d.isMcq) ...[
            const SizedBox(height: Spacing.lg),
            _McqOptions(
              detail: d,
              revealed: _panel == _ReaderPanel.directAnswer,
            ),
          ],
          if (_panel == _ReaderPanel.directAnswer) ...[
            const SizedBox(height: Spacing.lg),
            _DirectAnswerPanel(detail: d),
          ],
          if (_panel == _ReaderPanel.explanation) ...[
            const SizedBox(height: Spacing.lg),
            _ExplanationPanel(
              detail: d,
              onOpenLink: (link) => _openLink(link, plan),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          FilledButton.tonal(
            onPressed: _learnt
                ? null
                : () async {
                    final result = await ref
                        .read(pyqRepositoryProvider)
                        .markLearnt(widget.questionId);
                    if (!mounted) return;
                    switch (result) {
                      case Success():
                        setState(() => _learnt = true);
                      case Failure(:final message):
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
            child: Text(_learnt ? 'Marked as learnt' : 'Mark as learnt'),
          ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _DirectAnswerPanel extends StatelessWidget {
  const _DirectAnswerPanel({required this.detail});

  final PyqDetail detail;

  @override
  Widget build(BuildContext context) {
    final hasKey = detail.correctOption != null;
    if (!detail.canReadSample) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasKey) ...[
            ComicCard(child: Text('Correct option: ${detail.correctOption}')),
            const SizedBox(height: Spacing.sm),
          ],
          ComicCard(
            onTap: () => context.push(AppRoutes.upgradePath(PlanTier.pro)),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('Direct answer'),
              subtitle: Text('Included with Pro'),
            ),
          ),
        ],
      );
    }
    if (detail.sampleAnswer == null && !hasKey) {
      return const Text('No direct answer yet');
    }
    return ComicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasKey) Text('Correct option: ${detail.correctOption}'),
          if (detail.sampleAnswer != null) ...[
            if (hasKey) const SizedBox(height: Spacing.sm),
            MarkdownCopy(data: detail.sampleAnswer!),
          ],
        ],
      ),
    );
  }
}

class _ExplanationPanel extends ConsumerWidget {
  const _ExplanationPanel({required this.detail, required this.onOpenLink});

  final PyqDetail detail;
  final ValueChanged<ResourceLink> onOpenLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(preferredTextbookProvider);
    final citations = [...detail.textbookRefs];
    if (preferred != null) {
      citations.sort((a, b) {
        final ap = a.sheetKey == preferred ? 0 : 1;
        final bp = b.sheetKey == preferred ? 0 : 1;
        return ap.compareTo(bp);
      });
    }
    final keys = {
      for (final c in detail.textbookRefs)
        if (c.sheetKey != null) c.sheetKey!,
    };
    final links = [...detail.lessonResources, ...detail.questionResources];
    final explanation = detail.explanationText?.trim();
    final hasExplanation = explanation != null && explanation.isNotEmpty;
    if (!hasExplanation && citations.isEmpty && links.isEmpty) {
      return const Text('No explanation yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasExplanation) ComicCard(child: MarkdownCopy(data: explanation)),
        if (citations.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Textbook pages', style: Theme.of(context).textTheme.titleSmall),
          if (keys.length > 1) ...[
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final key in keys)
                  ChoiceChip(
                    label: Text(
                      citations
                          .firstWhere(
                            (c) => c.sheetKey == key,
                            orElse: () => citations.first,
                          )
                          .title,
                    ),
                    selected: preferred == key,
                    onSelected: (_) => ref
                        .read(preferredTextbookProvider.notifier)
                        .setKey(preferred == key ? null : key),
                  ),
              ],
            ),
          ],
          for (final c in citations)
            ComicCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(c.label),
              ),
            ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text(
            'More on this topic',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final link in links)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: ComicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                onTap: () => onOpenLink(link),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    link.isFree ? Icons.open_in_new : Icons.lock_outline,
                  ),
                  title: Text(link.title),
                  subtitle: link.sourceLabel == null
                      ? null
                      : Text(link.sourceLabel!),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _McqOptions extends StatelessWidget {
  const _McqOptions({required this.detail, required this.revealed});

  final PyqDetail detail;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final options = <String, String?>{
      'A': detail.optionA,
      'B': detail.optionB,
      'C': detail.optionC,
      'D': detail.optionD,
    };
    return Column(
      children: [
        for (final entry in options.entries)
          if (entry.value != null && entry.value!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: ComicCard(
                color: revealed && entry.key == detail.correctOption
                    ? Color.alphaBlend(
                        Colors.green.withValues(alpha: 0.18),
                        ComicColors.of(context).sticker,
                      )
                    : null,
                child: Text('${entry.key}. ${entry.value}'),
              ),
            ),
      ],
    );
  }
}
