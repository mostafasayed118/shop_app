import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/money.dart';
import '../../logic/settings/settings_cubit.dart';

/// Formats [amount] via [formatPrice] in the app's current display currency
/// and renders it with the app's standard price typography.
///
/// The currency comes from [SettingsCubit] (read reactively), so switching
/// currency in settings live-updates every price in the app. With no [style]
/// it uses `titleMedium` at `FontWeight.w700` (the catalogue tile treatment);
/// pass a [style] to override, and/or a [color] to recolor.
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
      formatPrice(amount, currency: context.watch<SettingsCubit>().state),
      maxLines: maxLines,
      overflow: overflow,
      style: effective?.copyWith(color: color),
    );
  }
}
