import 'package:e_commerce/data/models/currency.dart';
import 'package:e_commerce/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsRepository', () {
    test('round-trips a saved currency', () async {
      final repository = SettingsRepository();
      await repository.save(Currency.eur);

      expect(await repository.load(), Currency.eur);
    });

    test('returns null when nothing was saved', () async {
      final repository = SettingsRepository();
      expect(await repository.load(), isNull);
    });

    test('returns null for an unknown value', () async {
      SharedPreferences.setMockInitialValues({'currency': 'btc'});

      final repository = SettingsRepository();
      expect(await repository.load(), isNull);
    });
  });
}
