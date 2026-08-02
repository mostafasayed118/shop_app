import 'package:flutter/material.dart';

/// Compact − / count / + stepper used for choosing a quantity.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
  });

  final int quantity;
  final int min;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > min ? onDecrement : null,
            tooltip: 'Decrease',
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$quantity',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: onIncrement,
            tooltip: 'Increase',
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
