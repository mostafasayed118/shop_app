import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalogue_preferences.dart';

/// Persists the last-used search / category / sort configuration.
class CataloguePreferencesRepository {
  static const _key = 'catalogue_preferences';

  Future<CataloguePreferences?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      return CataloguePreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      // Corrupt or legacy payload: fall back to defaults.
      debugPrint('Failed to decode saved preferences: $error');
      return null;
    }
  }

  Future<void> save(CataloguePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
