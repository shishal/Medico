import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/widgets/markdown_copy.dart';

void main() {
  testWidgets('plain explanation text is visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownCopy(data: 'Because mitochondria produce ATP.')),
      ),
    );

    expect(
      find.text('Because mitochondria produce ATP.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('bold markdown renders the words', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownCopy(data: 'Give **four** differences.')),
      ),
    );

    expect(find.textContaining('four', findRichText: true), findsOneWidget);
    expect(find.textContaining('Give', findRichText: true), findsOneWidget);
  });
}
