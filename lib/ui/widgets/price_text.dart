import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

/// Formats [amount] via [formatPrice] and renders it with the app's standard
/// price typography.
///
/// With no [style] it uses `titleMedium` at `FontWeight.w700` (the catalogue
/// tile treatment); pass a [style] to override, and/or a [color] to recolor.
class PriceText extends StatelessWidget {
  const PriceText(
    this.amount, {
    super.key,
    this.style,
    this.color,
    this.maxLines,
    this.overflow,
  });

  final double amount;
  final TextStyle? style;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective =
        style ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Text(
      formatPrice(amount),
      maxLines: maxLines,
      overflow: overflow,
      style: effective?.copyWith(color: color),
    );
  }
}
