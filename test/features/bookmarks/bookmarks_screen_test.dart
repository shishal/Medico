import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/utils/result.dart';
import 'package:medico/core/utils/user_facing_error.dart';
import 'package:medico/features/bookmarks/domain/bookmarked_question.dart';
import 'package:medico/features/bookmarks/presentation/providers/bookmarks_provider.dart';
import 'package:medico/features/bookmarks/presentation/screens/bookmarks_screen.dart';

BookmarkedQuestion _item({
  required String id,
  String? text,
  String? subject,
  String? topic,
}) {
  return BookmarkedQuestion(
    questionId: id,
    createdAt: DateTime.utc(2026, 8, 1),
    questionText: text,
    subjectName: subject,
    topicName: topic,
  );
}

class _StubBookmarkedIds extends BookmarkedIds {
  _StubBookmarkedIds(this._ids);

  final Set<String> _ids;

  @override
  Future<Set<String>> build() async => _ids;

  @override
  Future<Result<void>> toggle(String questionId) async {
    final current = Set<String>.from(state.value ?? _ids);
    if (!current.add(questionId)) current.remove(questionId);
    state = AsyncData(current);
    return const Success(null);
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<BookmarkedQuestion> items,
  Set<String>? ids,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookmarksListProvider.overrideWith((ref) => items),
        bookmarkedIdsProvider.overrideWith(
          () => _StubBookmarkedIds(
            ids ?? {for (final item in items) item.questionId},
          ),
        ),
      ],
      child: const MaterialApp(home: BookmarksScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state explains how to bookmark', (tester) async {
    await _pumpScreen(tester, items: const []);

    expect(find.textContaining('No bookmarks yet'), findsOneWidget);
    expect(find.textContaining('Practice'), findsNothing);
  });

  testWidgets('lists bookmarks and offers practice', (tester) async {
    await _pumpScreen(
      tester,
      items: [
        _item(
          id: 'q1',
          text: 'Which organelle produces ATP?',
          subject: 'Anatomy',
          topic: 'Cell Biology',
        ),
        _item(
          id: 'q2',
          text: 'What is the first heart sound?',
          subject: 'Physiology',
          topic: 'CVS',
        ),
      ],
    );

    expect(find.text('Which organelle produces ATP?'), findsOneWidget);
    expect(find.text('Anatomy · Cell Biology'), findsOneWidget);
    expect(find.text('What is the first heart sound?'), findsOneWidget);
    expect(find.text('Practice 2 bookmarked questions'), findsOneWidget);
  });

  testWidgets('plan-locked bookmark fails gracefully', (tester) async {
    await _pumpScreen(
      tester,
      items: [
        _item(id: 'q-locked'),
        _item(id: 'q-open', text: 'Visible stem'),
      ],
    );

    expect(find.text('Unavailable on your plan'), findsOneWidget);
    expect(find.text('Upgrade to see this question.'), findsOneWidget);
    expect(find.text('Visible stem'), findsOneWidget);
    expect(find.text('Practice 1 bookmarked question'), findsOneWidget);
  });

  testWidgets('unbookmark hides the row immediately', (tester) async {
    await _pumpScreen(
      tester,
      items: [_item(id: 'q1', text: 'Which organelle produces ATP?')],
    );

    expect(find.text('Which organelle produces ATP?'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove bookmark'));
    await tester.pumpAndSettle();

    expect(find.text('Which organelle produces ATP?'), findsNothing);
    expect(find.textContaining('No bookmarks yet'), findsOneWidget);
  });

  testWidgets('error state shows offline copy and Retry', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksListProvider.overrideWith(
            (ref) => throw Exception(UserFacingError.offlineMessage),
          ),
          bookmarkedIdsProvider.overrideWith(
            () => _StubBookmarkedIds(const {}),
          ),
        ],
        child: const MaterialApp(home: BookmarksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UserFacingError.offlineMessage), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
