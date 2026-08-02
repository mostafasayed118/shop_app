import 'package:e_commerce/data/models/catalogue_preferences.dart';
import 'package:e_commerce/data/models/product_sort.dart';
import 'package:e_commerce/data/repositories/catalogue_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const preferences = CataloguePreferences(
    query: 'head',
    category: 'Audio',
    sortField: SortField.price,
    sortDirection: SortDirection.descending,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CataloguePreferencesRepository', () {
    test('round-trips the browsing configuration through JSON', () async {
      final repository = CataloguePreferencesRepository();
      await repository.save(preferences);

      expect(await repository.load(), preferences);
    });

    test('returns null when nothing was saved', () async {
      final repository = CataloguePreferencesRepository();
      expect(await repository.load(), isNull);
    });

    test('returns null for a corrupt payload', () async {
      SharedPreferences.setMockInitialValues({
        'catalogue_preferences': 'not-json{',
      });

      final repository = CataloguePreferencesRepository();
      expect(await repository.load(), isNull);
    });
  });
}
