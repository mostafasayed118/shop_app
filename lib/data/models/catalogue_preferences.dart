import 'package:equatable/equatable.dart';

import 'product_sort.dart';

/// The last-used catalogue browsing configuration (search text, category chip
/// and sort), persisted so it survives app restarts. Serialization lives in
/// the data layer.
class CataloguePreferences extends Equatable {
  const CataloguePreferences({
    this.query = '',
    this.category,
    this.sortField = SortField.featured,
    this.sortDirection = SortDirection.ascending,
  });

  factory CataloguePreferences.fromJson(Map<String, dynamic> json) {
    return CataloguePreferences(
      query: json['query'] as String? ?? '',
      category: json['category'] as String?,
      sortField:
          _enumByName(SortField.values, json['sortField'] as String?) ??
              SortField.featured,
      sortDirection:
          _enumByName(SortDirection.values, json['sortDirection'] as String?) ??
              SortDirection.ascending,
    );
  }

  final String query;
  final String? category;
  final SortField sortField;
  final SortDirection sortDirection;

  Map<String, dynamic> toJson() => {
    'query': query,
    'category': category,
    'sortField': sortField.name,
    'sortDirection': sortDirection.name,
  };

  @override
  List<Object?> get props => [query, category, sortField, sortDirection];
}

/// Matches an enum by [name], tolerating unknown/missing values from an
/// older or hand-edited payload.
T? _enumByName<T extends Enum>(List<T> values, String? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
