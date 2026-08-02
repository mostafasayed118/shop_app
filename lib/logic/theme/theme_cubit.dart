import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/repositories/theme_mode_repository.dart';

/// Owns the app's [ThemeMode]: defaults to following the system and, when a
/// [ThemeModeRepository] is wired in, restores a saved override on
/// construction and persists every user choice (fire-and-forget). Store
/// failures are logged and never crash the app.
class ThemeCubit extends Cubit<ThemeMode> {
  // Positional-optional so the private field can be an initializing formal
  // (a private *named* parameter would be unusable from other libraries).
  ThemeCubit([this._repository]) : super(ThemeMode.system) {
    _restore();
  }

  final ThemeModeRepository? _repository;

  /// True once the user has overridden; a late restore must not clobber it.
  bool _mutated = false;

  /// Serializes persist writes so a fast burst can't land out of order.
  final WriteQueue _writes = WriteQueue();

  Future<void> _restore() async {
    final repository = _repository;
    if (repository == null || isClosed) return;

    try {
      final saved = await repository.load();
      if (!isClosed && !_mutated && saved != null) {
        emit(saved);
      }
    } catch (error) {
      // A failed store read must not crash the app; stay on the system mode.
      debugPrint('Failed to restore theme preference: $error');
    }
  }

  /// Sets [mode] explicitly (overriding the system) and persists it.
  void setThemeMode(ThemeMode mode) {
    if (mode == state) {
      return; // No-op: nothing changed, skip the redundant write.
    }
    _mutated = true;
    emit(mode);
    _persist(mode);
  }

  /// Cycles the mode light → dark → system (sun → moon → auto), so a user
  /// who pinned a theme can always return to following the system.
  void cycleThemeMode() {
    setThemeMode(switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    });
  }

  void _persist(ThemeMode mode) {
    final repository = _repository;
    if (repository == null) return;
    _writes.enqueue(() async {
      try {
        await repository.save(mode);
      } catch (error) {
        debugPrint('Failed to persist theme preference: $error');
      }
    });
  }
}
