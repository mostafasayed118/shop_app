import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ShopApp wires the real persistence repositories, which read
  // SharedPreferences — tests mock the store.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'the toggle cycles light → dark → system, persists, and auto follows the OS',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<void> pumpApp() async {
        await tester.pumpWidget(const ShopApp());
        await tester.pump(const Duration(milliseconds: 800)); // repo delay
        await tester.pumpAndSettle();
      }

      ThemeData themeOf() =>
          Theme.of(tester.element(find.byType(ProductsScreen)));

      // Fresh app: default mode is system, so the button shows the auto glyph
      // and the theme resolves to the (light) platform brightness.
      await pumpApp();
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.light);

      // Tap 1 (system → light): pinned to the sun icon; still light on screen.
      await tester.tap(find.byTooltip('Follow system'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.light);

      // Tap 2 (light → dark): the moon icon and a dark screen.
      await tester.tap(find.byTooltip('Light mode'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.dark);

      // "Restart": a fresh app over the same store keeps the pinned dark mode.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await pumpApp();
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.dark);

      // Tap 3 (dark → system): back to the auto glyph and the light platform.
      await tester.tap(find.byTooltip('Dark mode'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.light);

      // The system preference now flips to dark — auto follows it live, no
      // tap needed. This is the "return to the system setting" payoff.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.dark);

      // "Restart" again: the auto mode itself is persisted, so a fresh app
      // under the dark platform boots straight into the dark theme.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await pumpApp();
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(themeOf().brightness, Brightness.dark);
    },
  );
}
