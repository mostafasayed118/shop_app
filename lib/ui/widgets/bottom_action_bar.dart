import 'package:flutter/material.dart';

/// Persistent bottom action area: the app's `SafeArea` + `16/8/16/16` padding
/// around a primary full-width [button].
///
/// Shared by the product detail screen (quantity stepper + "Add to cart") and
/// the cart's checkout bar (totals + "Checkout"). The button is stretched to
/// fill the bar; [above] hosts content shown above the button (e.g. a total
/// row) and [leading] a widget beside it (e.g. a quantity stepper).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.button,
    this.above,
    this.leading,
  });

  /// The primary action; stretched to fill the available width.
  final Widget button;

  /// Optional content shown above the button row; it keeps its own layout
  /// (e.g. the cart's totals Column is full-width with the summary line
  /// centered, exactly as it was before the extraction).
  final Widget? above;

  /// Optional widget shown to the left of the button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (above != null) ...[above!, const SizedBox(height: 12)],
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(child: button),
            ],
          ),
        ],
      ),
    );
  }
}
