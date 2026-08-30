import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../bookmarks/presentation/widgets/bookmark_icon_button.dart';
import '../../data/pyq_repository.dart';
import '../../domain/pyq_models.dart';
import '../providers/pyq_providers.dart';

class PyqReaderScreen extends ConsumerWidget {
  const PyqReaderScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(pyqDetailProvider(questionId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYQ'),
        actions: [
          BookmarkIconButton(questionId: questionId),
        ],
      ),
      body: detail.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(pyqDetailProvider(questionId)),
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
  bool _showSample = false;
  late bool _learnt;

  @override
  void initState() {
    super.initState();
    _learnt = widget.detail.questionLearnt;
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
    final years = d.appearances.map((a) => '${a.year} ${a.paperName}').join(' · ');

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        if (d.teaser.marks != null)
          Text(
            '${d.teaser.marks} marks'
            '${d.teaser.appearanceCount > 0 ? ' · appeared ${d.teaser.appearanceCount}×' : ''}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        const SizedBox(height: Spacing.sm),
        Text(d.teaser.questionText, style: Theme.of(context).textTheme.titleMedium),
        if (years.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(years, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: Spacing.lg),
        Text('Sample answer', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Spacing.sm),
        if (!d.canReadSample)
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.lock_outline),
            title: const Text('Show sample answer'),
            subtitle: const Text('Included with Pro'),
            onTap: () => context.push(AppRoutes.upgradePath(PlanTier.pro)),
          )
        else if (d.sampleAnswer == null)
          const Text('No sample answer yet')
        else if (!_showSample)
          OutlinedButton(
            onPressed: () => setState(() => _showSample = true),
            child: const Text('Show sample answer'),
          )
        else
          Text(d.sampleAnswer!),
        if (d.textbookRefs.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Textbook pages', style: Theme.of(context).textTheme.titleSmall),
          for (final c in d.textbookRefs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(c.label),
            ),
        ],
        ..._resourceSection('More on this topic', [...d.lessonResources, ...d.questionResources], plan),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
          child: Text(_learnt ? 'Marked as learnt' : 'Mark as learnt'),
        ),
      ],
    );
  }

  List<Widget> _resourceSection(String title, List<ResourceLink> links, PlanTier plan) {
    if (links.isEmpty) return const [];
    return [
      const SizedBox(height: Spacing.lg),
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      for (final link in links)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(link.isFree ? Icons.open_in_new : Icons.lock_outline),
          title: Text(link.title),
          subtitle: link.sourceLabel == null ? null : Text(link.sourceLabel!),
          onTap: () => _openLink(link, plan),
        ),
    ];
  }
}
