import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase [AuthException]s to user-readable messages for the UI.
abstract final class AuthFailure {
  static String fromException(AuthException exception) {
    final message = exception.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }

    if (message.contains('weak password') ||
        message.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }

    if (message.contains('valid email')) {
      return 'Please enter a valid email address.';
    }

    return 'Something went wrong. Please try again.';
  }
}
