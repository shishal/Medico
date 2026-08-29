import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/profile/data/checkout_launcher.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';
import 'package:medico/features/profile/presentation/providers/current_plan_provider.dart';
import 'package:medico/features/profile/presentation/screens/upgrade_prompt_screen.dart';

Future<void> _pumpUpgrade(
  WidgetTester tester, {
  required PlanTier requiredPlan,
  PlanTier currentPlan = PlanTier.free,
  required CheckoutLauncher launcher,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentPlanProvider.overrideWith((ref) async => currentPlan),
        checkoutLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(home: UpgradePromptScreen(requiredPlan: requiredPlan)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Free, Pro, and Elite comparison without in-app purchase', (
    tester,
  ) async {
    await _pumpUpgrade(
      tester,
      requiredPlan: PlanTier.pro,
      launcher: CheckoutLauncher(
        checkoutUri: Uri.parse('https://checkout.test/pay'),
        launch: (_) async => true,
      ),
    );

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Pro'), findsWidgets);
    expect(find.text('Elite'), findsWidgets);
    expect(find.text('Full explanations'), findsNWidgets(3));
    expect(find.textContaining('browser'), findsWidgets);

    expect(find.textContaining('Buy'), findsNothing);
    expect(find.textContaining('Purchase'), findsNothing);
    expect(find.textContaining('₹'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Continue in browser opens checkout for that plan', (
    tester,
  ) async {
    final opened = <Uri>[];
    await _pumpUpgrade(
      tester,
      requiredPlan: PlanTier.elite,
      launcher: CheckoutLauncher(
        checkoutUri: Uri.parse('https://checkout.test/pay'),
        launch: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );

    await tester.ensureVisible(find.text('Continue in browser — Elite'));
    await tester.tap(find.text('Continue in browser — Elite'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.queryParameters['plan'], 'elite');
  });

  testWidgets('Free card has no checkout action', (tester) async {
    await _pumpUpgrade(
      tester,
      requiredPlan: PlanTier.pro,
      launcher: CheckoutLauncher(
        checkoutUri: Uri.parse('https://checkout.test/pay'),
        launch: (_) async => true,
      ),
    );

    expect(find.text('Continue in browser — Free'), findsNothing);
    expect(find.text('Continue in browser — Pro'), findsOneWidget);
  });

  testWidgets('current paid plan hides its own checkout button', (
    tester,
  ) async {
    await _pumpUpgrade(
      tester,
      requiredPlan: PlanTier.elite,
      currentPlan: PlanTier.pro,
      launcher: CheckoutLauncher(
        checkoutUri: Uri.parse('https://checkout.test/pay'),
        launch: (_) async => true,
      ),
    );

    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Continue in browser — Pro'), findsNothing);
    expect(find.text('Continue in browser — Elite'), findsOneWidget);
  });
}
