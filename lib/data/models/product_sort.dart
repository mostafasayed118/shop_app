/// How the visible catalogue is ordered.
enum SortField { featured, price, name }

/// Order applied on top of [SortField]; ignored when the field is
/// [SortField.featured].
enum SortDirection { ascending, descending }
