import 'package:e_commerce/data/repositories/theme_mode_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeRepository', () {
    test('round-trips a saved mode', () async {
      final repository = ThemeModeRepository();
      await repository.save(ThemeMode.dark);

      expect(await repository.load(), ThemeMode.dark);
    });

    test('returns null when nothing was saved', () async {
      final repository = ThemeModeRepository();
      expect(await repository.load(), isNull);
    });

    test('returns null for an unknown value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});

      final repository = ThemeModeRepository();
      expect(await repository.load(), isNull);
    });
  });
}
