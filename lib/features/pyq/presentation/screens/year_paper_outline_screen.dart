import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../domain/paper_outline.dart';
import '../../domain/pyq_models.dart';
import '../providers/pyq_providers.dart';
import '../widgets/pyq_teaser_card.dart';

/// One exam year: Text vs Image entry, then pinned LAQ / Short notes / MCQ tabs.
class YearPaperOutlineScreen extends ConsumerWidget {
  const YearPaperOutlineScreen({
    super.key,
    required this.subjectId,
    required this.year,
    required this.title,
  });

  final String subjectId;
  final int year;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subjectPyqsProvider(subjectId));
    final filter = ref.watch(subjectPyqFiltersProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: Text('$title · $year')),
      body: async.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(subjectPyqsProvider(subjectId)),
        ),
        data: (feed) {
          List<PyqTeaser> forTab(PaperOutlineTab tab) => teasersForOutlineTab(
            teasers: feed.teasers,
            year: year,
            tab: tab,
            paperName: filter.paperName,
            topicId: filter.topicId,
          );
          return _OutlineBody(
            year: year,
            longAnswer: forTab(PaperOutlineTab.longAnswer),
            shortNotes: forTab(PaperOutlineTab.shortNotes),
            mcq: forTab(PaperOutlineTab.mcq),
          );
        },
      ),
    );
  }
}

class _OutlineBody extends StatefulWidget {
  const _OutlineBody({
    required this.year,
    required this.longAnswer,
    required this.shortNotes,
    required this.mcq,
  });

  final int year;
  final List<PyqTeaser> longAnswer;
  final List<PyqTeaser> shortNotes;
  final List<PyqTeaser> mcq;

  @override
  State<_OutlineBody> createState() => _OutlineBodyState();
}

class _OutlineBodyState extends State<_OutlineBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: PaperOutlineTab.values.length,
      vsync: this,
      initialIndex: defaultPaperOutlineTabIndex(
        longAnswer: widget.longAnswer,
        shortNotes: widget.shortNotes,
        mcq: widget.mcq,
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<PyqTeaser> _listFor(PaperOutlineTab tab) => switch (tab) {
    PaperOutlineTab.longAnswer => widget.longAnswer,
    PaperOutlineTab.shortNotes => widget.shortNotes,
    PaperOutlineTab.mcq => widget.mcq,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
          child: _PaperModeTiles(),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final tab in PaperOutlineTab.values)
              Tab(text: '${tab.label} ${_listFor(tab).length}'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final tab in PaperOutlineTab.values)
                _OutlineQuestionList(
                  year: widget.year,
                  tab: tab,
                  teasers: _listFor(tab),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaperModeTiles extends StatelessWidget {
  const _PaperModeTiles();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ComicCard(
            highlighted: true,
            child: Text(
              'Question paper Text',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: ComicCard(
            child: Column(
              children: [
                Text(
                  'Question paper Image',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Coming later',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineQuestionList extends StatelessWidget {
  const _OutlineQuestionList({
    required this.year,
    required this.tab,
    required this.teasers,
  });

  final int year;
  final PaperOutlineTab tab;
  final List<PyqTeaser> teasers;

  @override
  Widget build(BuildContext context) {
    if (teasers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [Text(tab.emptyMessage(year))],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: teasers.length,
      itemBuilder: (context, i) {
        final teaser = teasers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: PyqTeaserCard(
            teaser: teaser,
            index: i,
            onTap: () => context.push(AppRoutes.pyqPath(teaser.id)),
          ),
        );
      },
    );
  }
}
