import 'package:flutter/material.dart';

/// Rounded, flat (elevation-0) surface card in the theme's
/// [ColorScheme.surface] — the shared card treatment across catalogue tiles
/// and cart lines.
///
/// Elevation, color, clipping and the default 16px radius come from the app's
/// `cardTheme`; this widget adds the optional tap behaviour, inner [padding]
/// and outer [margin] (zero by default — unlike a raw [Card], which would add
/// its own 4px margin).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  /// Overrides the theme's default card radius; `null` uses the theme's.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    return Card(
      margin: margin,
      shape: borderRadius == null
          ? null
          : RoundedRectangleBorder(borderRadius: borderRadius!),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
