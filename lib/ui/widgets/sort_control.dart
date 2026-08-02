import 'package:flutter/material.dart';

import '../../data/models/product_sort.dart';

/// Sort menu: featured (catalogue order) or price/name in either direction,
/// with the active option checked.
class SortControl extends StatelessWidget {
  const SortControl({
    super.key,
    required this.field,
    required this.direction,
    required this.onSelected,
  });

  final SortField field;
  final SortDirection direction;
  final void Function(SortField field, SortDirection direction) onSelected;

  static const _labels = <(SortField, SortDirection), String>{
    (SortField.featured, SortDirection.ascending): 'Featured',
    (SortField.price, SortDirection.ascending): 'Price: low to high',
    (SortField.price, SortDirection.descending): 'Price: high to low',
    (SortField.name, SortDirection.ascending): 'Name: A to Z',
    (SortField.name, SortDirection.descending): 'Name: Z to A',
  };

  @override
  Widget build(BuildContext context) {
    final active = field != SortField.featured;
    final color = Theme.of(context).colorScheme;
    return PopupMenuButton<(SortField, SortDirection)>(
      tooltip: 'Sort products',
      icon: Icon(Icons.swap_vert, color: active ? color.primary : null),
      onSelected: (option) => onSelected(option.$1, option.$2),
      itemBuilder: (context) => [
        for (final entry in _labels.entries)
          CheckedPopupMenuItem<(SortField, SortDirection)>(
            value: entry.key,
            checked: entry.key == (field, direction),
            child: Text(entry.value),
          ),
      ],
    );
  }
}
