import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/models/currency.dart';
import '../../data/repositories/settings_repository.dart';

/// Owns the app's display [Currency]: defaults to USD and, when a
/// [SettingsRepository] is wired in, restores a saved preference on
/// construction and persists every user choice (fire-and-forget). Store
/// failures are logged and never crash the app.
///
/// This is the natural home for future persisted settings (each added as
/// another method + repository key) — the one genuinely app-wide preference
/// the theme/cart/orders cubits don't already own.
class SettingsCubit extends Cubit<Currency> {
  // Positional-optional so the private field can be an initializing formal
  // (a private *named* parameter would be unusable from other libraries).
  SettingsCubit([this._repository]) : super(Currency.usd) {
    _restore();
  }

  final SettingsRepository? _repository;

  /// True once the user has chosen a currency; a late restore must not
  /// clobber it.
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
      // A failed store read must not crash the app; stay on the default.
      debugPrint('Failed to restore currency preference: $error');
    }
  }

  /// Sets [currency] as the display currency and persists it.
  void setCurrency(Currency currency) {
    if (currency == state) {
      return; // No-op: nothing changed, skip the redundant write.
    }
    _mutated = true;
    emit(currency);
    _persist(currency);
  }

  void _persist(Currency currency) {
    final repository = _repository;
    if (repository == null) return;
    _writes.enqueue(() async {
      try {
        await repository.save(currency);
      } catch (error) {
        debugPrint('Failed to persist currency preference: $error');
      }
    });
  }
}
