import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the little "i" helps are shown. On at first; experienced players
/// switch them off in the settings. The choice is remembered.
class HelpNotifier extends Notifier<bool> {
  static const _key = 'help_enabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (_) {
      // No storage (for example in tests): keep the default.
    }
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, on);
    } catch (_) {
      // The choice then only lasts for this session.
    }
  }
}

final helpProvider = NotifierProvider<HelpNotifier, bool>(HelpNotifier.new);
