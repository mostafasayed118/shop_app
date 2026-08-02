import 'package:e_commerce/data/repositories/json_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('readStoredJson / writeStoredJson', () {
    test('round-trips a JSON value through the store', () async {
      await writeStoredJson('key', {'a': 1});

      final value = await readStoredJson<Map<String, dynamic>>(
        'key',
        fallback: const {},
        decode: (json) => json as Map<String, dynamic>,
      );
      expect(value, {'a': 1});
    });

    test('returns the fallback when the key is absent', () async {
      final value = await readStoredJson<String>(
        'missing',
        fallback: 'none',
        decode: (json) => json as String,
      );
      expect(value, 'none');
    });

    test('returns the fallback for an undecodable payload', () async {
      SharedPreferences.setMockInitialValues({'key': 'not-json{'});

      final value = await readStoredJson<String>(
        'key',
        fallback: 'none',
        decode: (json) => json as String,
      );
      expect(value, 'none');
    });

    test('returns the fallback when the payload has the wrong shape', () async {
      // Valid JSON, but a List where the decoder expects a String — the cast
      // inside [decode] throws a TypeError, which must also be contained.
      SharedPreferences.setMockInitialValues({'key': '[1, 2]'});

      final value = await readStoredJson<String>(
        'key',
        fallback: 'none',
        decode: (json) => json as String,
      );
      expect(value, 'none');
    });
  });
}
