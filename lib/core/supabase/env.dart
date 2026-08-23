import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase credentials from the gitignored `.env` file (see `.env.example`).
abstract final class SupabaseEnv {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get url {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty || value.contains('YOUR_PROJECT')) {
      throw StateError(
        'SUPABASE_URL is missing or still a placeholder. '
        'Copy .env.example to .env and fill in your Supabase project URL.',
      );
    }
    return value;
  }

  static String get anonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty || value == 'your_anon_key') {
      throw StateError(
        'SUPABASE_ANON_KEY is missing or still a placeholder. '
        'Copy .env.example to .env and fill in your Supabase anon key.',
      );
    }
    return value;
  }
}
