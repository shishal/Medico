import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medico/app.dart';

void main() {
  testWidgets('App launches splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MedicoApp(),
      ),
    );

    expect(find.text('Medico'), findsWidgets);
  });
}
