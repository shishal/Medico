import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/utils/user_facing_error.dart';

void main() {
  group('UserFacingError', () {
    test('maps SocketException to the offline message', () {
      const error = SocketException('Failed host lookup: example.com');
      expect(UserFacingError.looksOffline(error), isTrue);
      expect(
        UserFacingError.from(error, fallback: 'Could not load tests.'),
        UserFacingError.offlineMessage,
      );
    });

    test('maps "Failed to fetch" to the offline message', () {
      final error = Exception('Failed to fetch');
      expect(
        UserFacingError.from(error, fallback: 'Could not load tests.'),
        UserFacingError.offlineMessage,
      );
    });

    test('keeps a screen-specific fallback for unknown errors', () {
      expect(
        UserFacingError.from(
          StateError('boom'),
          fallback: 'Could not load tests. Please try again.',
        ),
        'Could not load tests. Please try again.',
      );
    });

    test('display unwraps Exception and keeps plan-lock copy', () {
      expect(
        UserFacingError.display(
          Exception('This test is not available on your current plan.'),
        ),
        'This test is not available on your current plan.',
      );
    });

    test('display maps a wrapped SocketException', () {
      expect(
        UserFacingError.display(
          const SocketException('Network is unreachable'),
        ),
        UserFacingError.offlineMessage,
      );
    });

    test('looksOffline is true for the already-mapped offline copy', () {
      expect(
        UserFacingError.looksOffline(UserFacingError.offlineMessage),
        isTrue,
      );
    });
  });
}
