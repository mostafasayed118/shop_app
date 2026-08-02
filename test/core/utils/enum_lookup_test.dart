import 'package:e_commerce/core/utils/enum_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Flavor { vanilla, chocolate }

enum _Color { red, green }

void main() {
  group('enumByName', () {
    test('matches a known name', () {
      expect(enumByName(_Flavor.values, 'chocolate'), _Flavor.chocolate);
    });

    test('returns null for an unknown name', () {
      expect(enumByName(_Flavor.values, 'strawberry'), isNull);
    });

    test('returns null for a missing name', () {
      expect(enumByName(_Flavor.values, null), isNull);
    });

    test('is generic across enum types', () {
      expect(enumByName(_Color.values, 'green'), _Color.green);
    });
  });
}
