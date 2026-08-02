import 'package:flutter/material.dart';

/// A soft circular badge around an icon — the shared visual for status views
/// (empty / error) and confirmation moments (order placed).
class CircleIcon extends StatelessWidget {
  const CircleIcon({
    super.key,
    required this.icon,
    this.size = 88,
    this.iconSize = 40,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            backgroundColor ?? scheme.primaryContainer.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color ?? scheme.primary),
    );
  }
}
