import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';

/// Persists the cart as a JSON list under a single SharedPreferences key.
///
/// Swapping to any other store later only requires reimplementing this class;
/// the rest of the app is unaware of where the cart is stored.
class CartRepository {
  static const _key = 'cart_items';

  Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      // Corrupt or legacy payload: start empty rather than crash.
      debugPrint('Failed to decode saved cart: $error');
      return const [];
    }
  }

  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
