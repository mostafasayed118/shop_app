import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = buildShopTheme();

  group('cardTheme', () {
    test('cards are flat surface panels', () {
      final card = theme.cardTheme;
      expect(card.elevation, 0);
      expect(card.color, theme.colorScheme.surface);
      expect(card.clipBehavior, Clip.antiAlias);
    });

    test('cards use the 16px radius', () {
      final shape = theme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
    });
  });

  group('inputDecorationTheme', () {
    test('text fields are filled surface panels', () {
      final input = theme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(input.fillColor, theme.colorScheme.surface);
      expect(input.contentPadding, EdgeInsets.zero);
    });

    test('the border is borderless with the 14px radius', () {
      final border = theme.inputDecorationTheme.border;
      expect(border, isA<OutlineInputBorder>());
      final outline = border as OutlineInputBorder;
      expect(outline.borderRadius, BorderRadius.circular(14));
      expect(outline.borderSide, BorderSide.none);
    });
  });

  group('dark theme', () {
    final dark = buildShopTheme(brightness: Brightness.dark);

    test('derives a dark color scheme', () {
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    test('uses a dark scaffold background', () {
      expect(dark.scaffoldBackgroundColor.computeLuminance(), lessThan(0.1));
    });

    test('cards and text fields still match the dark surface', () {
      expect(dark.cardTheme.color, dark.colorScheme.surface);
      expect(dark.inputDecorationTheme.fillColor, dark.colorScheme.surface);
    });
  });
}
