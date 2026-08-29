import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/utils/user_facing_error.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';
import 'package:medico/features/profile/presentation/providers/current_plan_provider.dart';
import 'package:medico/features/tests/domain/catalog_test.dart';
import 'package:medico/features/tests/domain/test_type.dart';
import 'package:medico/features/tests/presentation/providers/catalog_tests_provider.dart';
import 'package:medico/features/tests/presentation/screens/test_list_screen.dart';

class _StubCatalog extends CatalogTestsNotifier {
  _StubCatalog(this._tests);

  final List<CatalogTest> _tests;

  @override
  Future<List<CatalogTest>> build() async => _tests;
}

class _ErrorCatalog extends CatalogTestsNotifier {
  @override
  Future<List<CatalogTest>> build() async {
    throw Exception(UserFacingError.offlineMessage);
  }
}

Future<void> _pumpList(
  WidgetTester tester, {
  required CatalogTestsNotifier catalog,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogTestsProvider.overrideWith(() => catalog),
        currentPlanProvider.overrideWith((ref) async => PlanTier.free),
      ],
      child: const MaterialApp(home: TestListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty catalog shows an empty state', (tester) async {
    await _pumpList(tester, catalog: _StubCatalog(const []));

    expect(find.text('No tests available yet.'), findsOneWidget);
  });

  testWidgets('error state shows offline copy and Retry', (tester) async {
    await _pumpList(tester, catalog: _ErrorCatalog());

    expect(find.text(UserFacingError.offlineMessage), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('lists unlocked tests', (tester) async {
    await _pumpList(
      tester,
      catalog: _StubCatalog(const [
        CatalogTest(
          id: 't1',
          title: 'Mini Test 1',
          testType: TestType.mini,
          requiredPlan: PlanTier.free,
          totalDurationMinutes: 20,
          totalQuestions: 10,
          isSectional: false,
        ),
      ]),
    );

    expect(find.text('Mini Test 1'), findsOneWidget);
    expect(find.text('10 questions · 20 min'), findsOneWidget);
  });
}
