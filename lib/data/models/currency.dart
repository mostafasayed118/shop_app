/// Display currencies the catalogue can be priced in. Each carries its ISO
/// code, symbol and a human-readable label for the settings picker.
///
/// The built-in `Enum.name` (constant name, e.g. `usd`) is what gets
/// persisted; [label] is display-only.
enum Currency {
  usd(code: 'USD', symbol: r'$', label: 'US Dollar'),
  eur(code: 'EUR', symbol: '€', label: 'Euro'),
  gbp(code: 'GBP', symbol: '£', label: 'British Pound'),
  jpy(code: 'JPY', symbol: '¥', label: 'Japanese Yen');

  const Currency({
    required this.code,
    required this.symbol,
    required this.label,
  });

  final String code;
  final String symbol;
  final String label;
}
