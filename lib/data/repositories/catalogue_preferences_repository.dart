import '../models/catalogue_preferences.dart';
import 'json_store.dart';

/// Persists the last-used search / category / sort configuration.
class CataloguePreferencesRepository {
  static const _key = 'catalogue_preferences';

  Future<CataloguePreferences?> load() async {
    return readStoredJson(
      _key,
      fallback: null,
      decode: (json) =>
          CataloguePreferences.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> save(CataloguePreferences preferences) async {
    await writeStoredJson(_key, preferences.toJson());
  }
}
