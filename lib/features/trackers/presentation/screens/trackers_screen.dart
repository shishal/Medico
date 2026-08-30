import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../../core/widgets/coverage_ring.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/domain/catalog_models.dart';
import '../../../progress/domain/progress_models.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/trackers_repository.dart';

class TrackersScreen extends ConsumerWidget {
  const TrackersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(trackerListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.trackerCreate),
        label: const Text('Custom tracker'),
        icon: const Icon(Icons.add),
      ),
      body: list.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(trackerListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AsyncEmptyView(
              message: 'No trackers yet. Create one for your next internal.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: _TrackerCard(tracker: items[i], index: i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.tracker, required this.index});

  final TrackerSummary tracker;
  final int index;

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final tint = StickerFills.tintAt(index, Theme.of(context).brightness);
    // Server-sent percent (0–100). Display only — not recomputed here.
    final progress = tracker.percent.toDouble() / 100;

    return ComicCard(
      color: Color.alphaBlend(tint.withValues(alpha: 0.4), comic.sticker),
      child: Row(
        children: [
          CoverageRing(
            progress: progress.clamp(0.0, 1.0),
            size: 48,
            child: Text(
              '${tracker.percent.round()}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracker.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  tracker.kind == 'university_window'
                      ? 'University calendar · ${tracker.done}/${tracker.total}'
                      : 'Custom · ${tracker.done}/${tracker.total}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTrackerScreen extends ConsumerStatefulWidget {
  const CreateTrackerScreen({super.key});

  @override
  ConsumerState<CreateTrackerScreen> createState() =>
      _CreateTrackerScreenState();
}

class _CreateTrackerScreenState extends ConsumerState<CreateTrackerScreen> {
  final _title = TextEditingController();
  final _selected = <String>{};
  List<LessonPickerItem> _lessons = const [];
  bool _loadingLessons = true;
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadLessons);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    final profile = await ref.read(userProfileProvider.future);
    final result = await ref
        .read(catalogRepositoryProvider)
        .fetchLessonsForPhase(profile?.mbbsPhaseId);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _lessons = value;
          _loadingLessons = false;
        });
      case Failure(:final message):
        setState(() {
          _loadError = message;
          _loadingLessons = false;
        });
    }
  }

  Future<void> _save() async {
    final name = _title.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name the tracker first.')));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one lesson.')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(trackersRepositoryProvider)
        .createCustom(title: name, lessonIds: _selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        ref.invalidate(trackerListProvider);
        context.go(AppRoutes.trackers);
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New tracker')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Anatomy internal 1)',
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Pick lessons from your year. Marking a lesson learnt counts toward this tracker’s percent.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          if (_loadingLessons) const LinearProgressIndicator(),
          if (_loadError != null) Text(_loadError!),
          if (!_loadingLessons && _lessons.isEmpty)
            const Text('No lessons in the catalog yet.'),
          for (final lesson in _lessons)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selected.contains(lesson.id),
              title: Text(lesson.name),
              subtitle: Text('${lesson.subjectName} · ${lesson.topicName}'),
              onChanged: (on) {
                setState(() {
                  if (on == true) {
                    _selected.add(lesson.id);
                  } else {
                    _selected.remove(lesson.id);
                  }
                });
              },
            ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save tracker'),
          ),
        ],
      ),
    );
  }
}
