import '../../core/utils/enum_lookup.dart';
import '../models/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists app settings (currently just the display [Currency]) as plain
/// strings under a single SharedPreferences key. `null` (nothing saved) means
/// "use the default" (USD).
class SettingsRepository {
  static const _key = 'currency';

  /// Returns the saved currency, or `null` when the user has never chosen one
  /// (unknown or legacy values also resolve to `null` → default).
  Future<Currency?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return enumByName(Currency.values, prefs.getString(_key));
  }

  Future<void> save(Currency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, currency.name);
  }
}
