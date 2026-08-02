import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ShopApp wires the real persistence repositories, which read
  // SharedPreferences — tests mock the store.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders with the dark theme when the system prefers dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const ShopApp());
    await tester.pump(const Duration(milliseconds: 800)); // repo delay
    await tester.pumpAndSettle();

    // ThemeMode.system resolved the dark preference into the dark theme, and
    // the catalogue still loads.
    final context = tester.element(find.byType(ProductsScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
  });
}
