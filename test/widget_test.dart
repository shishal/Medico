import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medico/app.dart';

void main() {
  testWidgets('Hello screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MedicoApp(),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
