import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/widgets/comic_select_sheet.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  required List<String> items,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showComicSelectSheet<String>(
              context: context,
              title: 'College',
              items: items,
              labelOf: (item) => item,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('short lists stay tap-to-pick with no search field', (
    tester,
  ) async {
    await _openSheet(tester, items: const ['2026', '2025', '2024']);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('long lists show a search field that filters rows', (
    tester,
  ) async {
    await _openSheet(
      tester,
      items: [for (var i = 0; i < 10; i++) 'College $i'],
    );

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'College 3');
    await tester.pump();

    expect(find.text('College 3'), findsWidgets);
    expect(find.text('College 0'), findsNothing);
  });
}
