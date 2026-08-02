import 'package:flutter/material.dart';

/// Padding around the product catalogue grid — and its loading skeleton.
const kProductGridPadding = EdgeInsets.all(16);

/// The grid geometry shared by the catalogue grid and its loading skeleton, so
/// tiles never change size between the placeholder and the real content.
SliverGridDelegateWithFixedCrossAxisCount productGridDelegate(
  int crossAxisCount,
) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    // Square image + fixed text block underneath.
    childAspectRatio: 0.6,
  );
}
