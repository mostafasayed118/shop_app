import 'dart:async';

import 'package:e_commerce/data/repositories/theme_mode_repository.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of the theme-mode store for persistence tests.
class _FakeThemeRepository extends ThemeModeRepository {
  ThemeMode? stored;

  @override
  Future<ThemeMode?> load() async => stored;

  @override
  Future<void> save(ThemeMode mode) async {
    stored = mode;
  }
}

/// Like [_FakeThemeRepository] but whose [load] stays pending until the test
/// explicitly completes it, so the restore can race a user action
/// deterministically (no wall-clock sleeps).
class _GatedFakeThemeRepository extends _FakeThemeRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<ThemeMode?> load() async {
    await gate.future;
    return stored;
  }
}

void main() {
  test('starts in system mode', () {
    final cubit = ThemeCubit();
    expect(cubit.state, ThemeMode.system);
    cubit.close();
  });

  test('setThemeMode updates the state and persists', () async {
    final repository = _FakeThemeRepository();
    final cubit = ThemeCubit(repository);

    cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state, ThemeMode.dark);

    // The write is queued; flush the microtask chain.
    await Future<void>.delayed(Duration.zero);
    expect(repository.stored, ThemeMode.dark);
    cubit.close();
  });

  test(
    'setting the current mode again is a no-op (no redundant write)',
    () async {
      final repository = _FakeThemeRepository();
      final cubit = ThemeCubit(repository);

      cubit.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      final writesBefore = repository.stored;

      // Re-setting the same mode must neither re-emit nor rewrite the store.
      cubit.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(repository.stored, writesBefore);
      cubit.close();
    },
  );

  test(
    'cycleThemeMode walks light → dark → system and back to light',
    () async {
      final repository = _FakeThemeRepository();
      final cubit = ThemeCubit(repository);

      // The default state is system, so the cycle starts there.
      cubit.cycleThemeMode(); // system → light
      expect(cubit.state, ThemeMode.light);
      cubit.cycleThemeMode(); // light → dark
      expect(cubit.state, ThemeMode.dark);
      cubit.cycleThemeMode(); // dark → system (back to following the OS)
      expect(cubit.state, ThemeMode.system);
      cubit.cycleThemeMode(); // system → light again
      expect(cubit.state, ThemeMode.light);

      // Each step is persisted, so the last pin survives a restart.
      await Future<void>.delayed(Duration.zero);
      expect(repository.stored, ThemeMode.light);
      cubit.close();
    },
  );

  test('restores a saved override on construction', () async {
    final repository = _FakeThemeRepository()..stored = ThemeMode.light;
    final cubit = ThemeCubit(repository);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, ThemeMode.light);
    cubit.close();
  });

  test('a late restore does not clobber a user action', () async {
    final repository = _GatedFakeThemeRepository()..stored = ThemeMode.light;
    final cubit = ThemeCubit(repository);

    // The restore is still pending when the user overrides…
    cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state, ThemeMode.dark);

    // …and even after the restore finally lands, the override wins.
    repository.gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, ThemeMode.dark);
    cubit.close();
  });
}
