import 'package:flutter/material.dart';

/// Horizontally scrollable filter chips with an implicit "All" option.
///
/// Tapping the active chip returns to "All" (passes `null`). The chip list is
/// derived by the caller, keeping this widget decoupled from any data model.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              showCheckmark: false,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                showCheckmark: false,
                // Tapping the active chip returns to "All".
                onSelected: (_) =>
                    onSelected(selectedCategory == category ? null : category),
              ),
            ),
        ],
      ),
    );
  }
}
