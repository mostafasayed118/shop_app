/// Formats [count] together with [noun], pluralizing with an "s" (or the
/// full [plural] form) unless [count] is exactly 1.
///
/// Examples: `pluralize(1, 'item')` → `"1 item"`, `pluralize(3, 'item')` →
/// `"3 items"`, `pluralize(2, 'box', plural: 'boxes')` → `"2 boxes"`.
String pluralize(int count, String noun, {String? plural}) {
  if (count == 1) return '$count $noun';
  return '$count ${plural ?? '${noun}s'}';
}

/// Formats [date] as `dd/MM/yyyy`, e.g. the 1st of July 2026 → `"01/07/2026"`.
/// Dependency-free: `intl` would be overkill for a single short format.
String formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
