import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads the JSON payload stored under [key] and decodes it with [decode],
/// returning [fallback] when the key is absent or the payload is corrupt —
/// a broken store must never crash the app.
///
/// Shared by the persistence repositories so every read follows the same
/// getString → jsonDecode → fallback contract.
Future<T> readStoredJson<T>(
  String key, {
  required T fallback,
  required T Function(Object? json) decode,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(key);
  if (raw == null) return fallback;
  try {
    return decode(jsonDecode(raw));
  } catch (error) {
    // Covers a FormatException from jsonDecode as well as a TypeError from a
    // cast inside [decode] (payload with the wrong shape).
    debugPrint('Failed to decode stored value for "$key": $error');
    return fallback;
  }
}

/// Encodes [value] with [jsonEncode] and stores it under [key].
Future<void> writeStoredJson(String key, Object? value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, jsonEncode(value));
}
