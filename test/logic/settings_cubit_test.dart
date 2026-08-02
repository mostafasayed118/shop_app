import 'dart:async';

import 'package:e_commerce/data/models/currency.dart';
import 'package:e_commerce/data/repositories/settings_repository.dart';
import 'package:e_commerce/logic/settings/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of the settings store for persistence tests.
class _FakeSettingsRepository extends SettingsRepository {
  Currency? stored;

  @override
  Future<Currency?> load() async => stored;

  @override
  Future<void> save(Currency currency) async {
    stored = currency;
  }
}

/// Like [_FakeSettingsRepository] but whose [load] stays pending until the
/// test explicitly completes it, so the restore can race a user action
/// deterministically (no wall-clock sleeps).
class _GatedFakeSettingsRepository extends _FakeSettingsRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Currency?> load() async {
    await gate.future;
    return stored;
  }
}

void main() {
  test('defaults to USD', () {
    final cubit = SettingsCubit();
    expect(cubit.state, Currency.usd);
    cubit.close();
  });

  test('setCurrency updates the state and persists', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);

    cubit.setCurrency(Currency.eur);
    expect(cubit.state, Currency.eur);

    // The write is queued; flush the microtask chain.
    await Future<void>.delayed(Duration.zero);
    expect(repository.stored, Currency.eur);
    cubit.close();
  });

  test('setting the current currency again is a no-op (no redundant write)', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(repository);

    cubit.setCurrency(Currency.gbp);
    await Future<void>.delayed(Duration.zero);
    final writesBefore = repository.stored;

    // Re-setting the same currency must neither re-emit nor rewrite the store.
    cubit.setCurrency(Currency.gbp);
    await Future<void>.delayed(Duration.zero);
    expect(repository.stored, writesBefore);
    cubit.close();
  });

  test('restores a saved currency on construction', () async {
    final repository = _FakeSettingsRepository()..stored = Currency.jpy;
    final cubit = SettingsCubit(repository);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, Currency.jpy);
    cubit.close();
  });

  test('a late restore does not clobber a user action', () async {
    final repository = _GatedFakeSettingsRepository()..stored = Currency.jpy;
    final cubit = SettingsCubit(repository);

    // The restore is still pending when the user chooses a currency…
    cubit.setCurrency(Currency.eur);
    expect(cubit.state, Currency.eur);

    // …and even after the restore finally lands, the choice wins.
    repository.gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, Currency.eur);
    cubit.close();
  });
}
