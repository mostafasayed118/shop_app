/// Formats [count] together with [noun], pluralizing with an "s" (or the
/// full [plural] form) unless [count] is exactly 1.
///
/// Examples: `pluralize(1, 'item')` → `"1 item"`, `pluralize(3, 'item')` →
/// `"3 items"`, `pluralize(2, 'box', plural: 'boxes')` → `"2 boxes"`.
String pluralize(int count, String noun, {String? plural}) {
  if (count == 1) return '$count $noun';
  return '$count ${plural ?? '${noun}s'}';
}
