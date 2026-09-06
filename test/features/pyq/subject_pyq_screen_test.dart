import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medico/core/router/app_routes.dart';
import 'package:medico/core/utils/result.dart';
import 'package:medico/features/bookmarks/presentation/providers/bookmarks_provider.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';
import 'package:medico/features/pyq/domain/pyq_models.dart';
import 'package:medico/features/pyq/domain/question_format.dart';
import 'package:medico/features/pyq/domain/subject_pyq_filters.dart';
import 'package:medico/features/pyq/presentation/providers/pyq_providers.dart';
import 'package:medico/features/pyq/presentation/screens/subject_pyq_screen.dart';

PyqTeaser _teaser({
  required String id,
  required String text,
  required String topicId,
  required String topicName,
  List<String> papers = const ['Paper I'],
  List<int> years = const [2024],
  String kind = 'pyq_theory',
  num marks = 10,
}) {
  return PyqTeaser(
    id: id,
    topicId: topicId,
    questionText: text,
    marks: marks,
    requiredPlan: PlanTier.free,
    appearanceCount: years.length,
    kind: kind,
    appearanceYears: years,
    paperNames: papers,
    topicName: topicName,
  );
}

void main() {
  test('filterSubjectPyqs keeps mixed-paper stems until a chapter is picked', () {
    final mixed = [
      _teaser(
        id: 'q1',
        text: 'Coronary arteries',
        topicId: 'thorax',
        topicName: 'Thorax',
        papers: const ['Paper II'],
      ),
      _teaser(
        id: 'q2',
        text: 'Femoral triangle',
        topicId: 'll',
        topicName: 'Lower limb',
        papers: const ['Paper II'],
      ),
    ];
    expect(filterSubjectPyqs(teasers: mixed).map((t) => t.id), ['q1', 'q2']);
    expect(
      filterSubjectPyqs(teasers: mixed, topicId: 'll').single.id,
      'q2',
    );
    expect(
      filterSubjectPyqs(
        teasers: mixed,
        paperName: 'Paper I',
      ),
      isEmpty,
    );
    expect(
      filterSubjectPyqs(
        teasers: mixed,
        paperName: 'Paper II',
        year: 2024,
      ).map((t) => t.id),
      ['q1', 'q2'],
    );
  });

  test('filterSubjectPyqs puts essays first when a full paper is selected', () {
    final teasers = [
      _teaser(
        id: 'mcq',
        text: 'MCQ',
        topicId: 't',
        topicName: 'Thorax',
        kind: 'mcq',
        marks: 1,
      ),
      _teaser(
        id: 'essay',
        text: 'Essay',
        topicId: 't',
        topicName: 'Thorax',
        marks: 10,
      ),
    ];
    final ordered = filterSubjectPyqs(
      teasers: teasers,
      paperName: 'Paper I',
      year: 2024,
    );
    expect(ordered.first.id, 'essay');
    expect(ordered.last.id, 'mcq');
  });

  testWidgets('subject screen shows PYQs without opening a topic first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: AppRoutes.subjectPath('anat', 'Anatomy'),
      routes: [
        GoRoute(
          path: AppRoutes.subject,
          builder: (_, state) => SubjectPyqScreen(
            subjectId: state.pathParameters['subjectId']!,
            title: state.uri.queryParameters['title'] ?? 'Subject',
          ),
        ),
        GoRoute(
          path: AppRoutes.subjectTopics,
          builder: (_, _) => const Text('Chapter list'),
        ),
        GoRoute(
          path: AppRoutes.pyq,
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subjectPyqsProvider.overrideWith((ref, id) async {
            expect(id, 'anat');
            return PyqSubjectFeed(
              teasers: [
                _teaser(
                  id: 'q1',
                  text: 'Describe the femoral triangle.',
                  topicId: 'll',
                  topicName: 'Lower limb',
                  papers: const ['Paper II'],
                ),
                _teaser(
                  id: 'q2',
                  text: 'Brachial plexus',
                  topicId: 'ul',
                  topicName: 'Upper limb',
                  papers: const ['Paper I'],
                  years: const [2023],
                ),
              ],
              usingFallback: false,
              paperNames: const ['Paper I', 'Paper II'],
              years: const [2024, 2023],
              chapters: const [
                PyqChapter(id: 'ul', name: 'Upper limb'),
                PyqChapter(id: 'll', name: 'Lower limb'),
              ],
            );
          }),
          bookmarkedIdsProvider.overrideWith(_StubBookmarkedIds.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Describe the femoral triangle.'), findsOneWidget);
    expect(find.text('Brachial plexus'), findsOneWidget);
    expect(find.text('Previous year questions'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Paper II'));
    await tester.pumpAndSettle();
    expect(find.text('Describe the femoral triangle.'), findsOneWidget);
    expect(find.text('Brachial plexus'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'All papers'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Upper limb'));
    await tester.pumpAndSettle();
    expect(find.text('Brachial plexus'), findsOneWidget);
    expect(find.text('Describe the femoral triangle.'), findsNothing);

    await tester.tap(find.text('Chapters'));
    await tester.pumpAndSettle();
    expect(find.text('Chapter list'), findsOneWidget);
  });
}

class _StubBookmarkedIds extends BookmarkedIds {
  @override
  Future<Set<String>> build() async => {};

  @override
  Future<Result<void>> toggle(String questionId) async {
    return const Success(null);
  }
}
