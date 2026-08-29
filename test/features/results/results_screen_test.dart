import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/router/app_routes.dart';
import 'package:medico/features/results/presentation/screens/results_screen.dart';

void main() {
  testWidgets('shows Practice Similar Again only for practice sessions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResultsScreen(
            attemptId: 'a1',
            testId: 't1',
            isPractice: true,
          ),
        ),
      ),
    );

    expect(find.text('Practice Similar Again'), findsOneWidget);
  });

  testWidgets('hides Practice Similar Again for catalog results',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResultsScreen(attemptId: 'a1', testId: 't1'),
        ),
      ),
    );

    expect(find.text('Practice Similar Again'), findsNothing);
  });

  test('resultsPath includes practice query flags', () {
    expect(
      AppRoutes.resultsPath('a1', testId: 't1', isPractice: true),
      '/results/a1?testId=t1&practice=1',
    );
    expect(AppRoutes.resultsPath('a1'), '/results/a1');
  });
}
