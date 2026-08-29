import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/tests/domain/submit_backoff.dart';

void main() {
  test('doubles until the 60 second cap', () {
    expect(SubmitBackoff.delayFor(1), const Duration(seconds: 2));
    expect(SubmitBackoff.delayFor(2), const Duration(seconds: 4));
    expect(SubmitBackoff.delayFor(3), const Duration(seconds: 8));
    expect(SubmitBackoff.delayFor(5), const Duration(seconds: 32));
    expect(SubmitBackoff.delayFor(6), const Duration(seconds: 60));
    expect(SubmitBackoff.delayFor(20), SubmitBackoff.maxDelay);
  });
}
