import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme-mode override as a plain string under a single
/// SharedPreferences key. `null` (nothing saved) means "follow the system".
class ThemeModeRepository {
  static const _key = 'theme_mode';

  static const _names = <ThemeMode, String>{
    ThemeMode.system: 'system',
    ThemeMode.light: 'light',
    ThemeMode.dark: 'dark',
  };

  /// Returns the saved override, or `null` when the user has never overridden
  /// (unknown or legacy values also resolve to `null` → system mode).
  Future<ThemeMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    for (final entry in _names.entries) {
      if (entry.value == raw) return entry.key;
    }
    return null;
  }

  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _names[mode]!);
  }
}
