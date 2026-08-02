import 'package:flutter/material.dart';

/// Lets a [State] own a single snackbar "slot" so it can replace or dismiss
/// exactly its own message without yanking unrelated toasts — other owners
/// manage their messages through their own slots.
///
/// Owners never stomp on each other: if a different owner's message is still
/// on screen, a new one is *queued* behind it (Flutter shows it once the
/// current one dismisses). This replaces the old
/// `hideCurrentSnackBar()..showSnackBar()` pattern, which dismissed whatever
/// was showing.
///
/// Example: the products screen's "couldn't refresh" message and a card's
/// "added to cart" message no longer stomp on each other; each owner just
/// replaces its own.
mixin OwnedSnackBar<T extends StatefulWidget> on State<T> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _ownedSnackBar;

  /// Shows [snackBar] as this owner's message, replacing a previously shown
  /// owned one. Other owners' snackbars are left untouched (they queue behind
  /// this one if still on screen).
  void showOwnedSnackBar(SnackBar snackBar) {
    _ownedSnackBar?.close();
    final controller = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _ownedSnackBar = controller;
    // Forget the reference once the message is gone (auto-dismiss timer or
    // close()), so we never close a snackbar that is no longer showing.
    controller.closed.whenComplete(() {
      if (_ownedSnackBar == controller) _ownedSnackBar = null;
    });
  }

  /// Shows a plain-text toast as this owner's message — a convenience over
  /// [showOwnedSnackBar] for the common `SnackBar(content: Text(...))` case.
  void showOwnedToast(String message) =>
      showOwnedSnackBar(SnackBar(content: Text(message)));

  /// Dismisses this owner's snackbar if it is still on screen; a no-op
  /// otherwise.
  void hideOwnedSnackBar() => _ownedSnackBar?.close();
}
