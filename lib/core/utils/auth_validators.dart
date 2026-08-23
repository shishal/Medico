/// Client-side validation helpers — block empty submissions before network calls.
abstract final class AuthValidators {
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Password is required.';
    }
    if (trimmed.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
