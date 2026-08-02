/// Looks up an enum value by its [name], returning `null` for unknown or
/// missing names instead of throwing (unlike the built-in `EnumByName.byName`,
/// which throws for unknown names).
///
/// Useful when deserializing payloads that may come from an older or
/// hand-edited source, so unknown values degrade to the caller's fallback.
///
/// Example: `enumByName(SortField.values, 'price')` → `SortField.price`,
/// `enumByName(SortField.values, 'old-value')` → `null`.
T? enumByName<T extends Enum>(List<T> values, String? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
