import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferred_textbook_provider.g.dart';

const _prefKey = 'preferred_textbook_key';

/// Local textbook preference so PYQ cards highlight one citation first.
@Riverpod(keepAlive: true)
class PreferredTextbook extends _$PreferredTextbook {
  @override
  String? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != state) state = raw;
  }

  Future<void> setKey(String? sheetKey) async {
    state = sheetKey;
    final prefs = await SharedPreferences.getInstance();
    if (sheetKey == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, sheetKey);
    }
  }
}
