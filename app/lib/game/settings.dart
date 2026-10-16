import 'package:flutter/services.dart';
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

/// A small remembered setting (a yes/no or a number) in the shared
/// preferences. Without storage (tests) it only lives for the session.
class _Stored<T extends Object> extends Notifier<T> {
  _Stored(this.key, this.initial);

  final String key;
  final T initial;

  @override
  T build() {
    _load();
    return initial;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(key);
      if (value is T) state = value;
    } catch (_) {}
  }

  Future<void> set(T value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) await prefs.setBool(key, value);
      if (value is int) await prefs.setInt(key, value);
    } catch (_) {}
  }
}

/// Start speed of the match ticker: 0 slow, 1 normal, 2 fast.
final tickerSpeedProvider = NotifierProvider<_Stored<int>, int>(
  () => _Stored<int>('ticker_speed', 0),
);

/// Whether the phone buzzes when your team scores.
final vibrationProvider = NotifierProvider<_Stored<bool>, bool>(
  () => _Stored<bool>('vibration', true),
);

/// Whether sounds play (the sounds themselves are still to come).
final soundProvider = NotifierProvider<_Stored<bool>, bool>(
  () => _Stored<bool>('sound', true),
);

/// Whether the assistant re-sets the line-up when a player of it is out
/// (injured or banned). Off: "Weiter" stops and the manager does it.
final autoLineupProvider = NotifierProvider<_Stored<bool>, bool>(
  () => _Stored<bool>('auto_lineup', false),
);

/// One strong buzz, where the device can (not in the iPhone browser).
Future<void> buzz() async {
  try {
    await HapticFeedback.heavyImpact();
  } catch (_) {}
}
