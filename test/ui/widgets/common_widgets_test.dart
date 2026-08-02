import 'package:e_commerce/data/models/currency.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/models/product_sort.dart';
import 'package:e_commerce/logic/settings/settings_cubit.dart';
import 'package:e_commerce/ui/widgets/bottom_action_bar.dart';
import 'package:e_commerce/ui/widgets/category_chips.dart';
import 'package:e_commerce/ui/widgets/circle_icon.dart';
import 'package:e_commerce/ui/widgets/price_text.dart';
import 'package:e_commerce/ui/widgets/product_image.dart';
import 'package:e_commerce/ui/widgets/search_field.dart';
import 'package:e_commerce/ui/widgets/sort_control.dart';
import 'package:e_commerce/ui/widgets/surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = Product(
    id: '1',
    name: 'Aurora Wireless Headphones',
    description: 'Over-ear headphones.',
    price: 249.99,
    imageAsset: 'assets/images/product_1.png',
    category: 'Audio',
  );

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('SearchField', () {
    testWidgets('fires onChanged while typing and shows a clear button', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        wrap(SearchField(query: '', onChanged: calls.add)),
      );

      await tester.enterText(find.byType(TextField), 'shoes');
      expect(calls, ['shoes']);
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(calls.last, '');
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('re-syncs its text when the query changes externally', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(SearchField(query: 'a', onChanged: (_) {})));
      expect(find.widgetWithText(TextField, 'a'), findsOneWidget);

      await tester.pumpWidget(wrap(SearchField(query: 'b', onChanged: (_) {})));
      expect(find.widgetWithText(TextField, 'b'), findsOneWidget);
    });
  });

  group('CategoryChips', () {
    testWidgets('renders All plus the categories and reports selections', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          CategoryChips(
            categories: const ['Audio', 'Bags'],
            selectedCategory: null,
            onSelected: (value) => selected = value,
          ),
        ),
      );

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Audio'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Audio'));
      expect(selected, 'Audio');
    });

    testWidgets('tapping the active chip returns to All', (tester) async {
      String? selected = 'Audio';
      await tester.pumpWidget(
        wrap(
          CategoryChips(
            categories: const ['Audio'],
            selectedCategory: 'Audio',
            onSelected: (value) => selected = value,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Audio'));
      expect(selected, isNull);
    });
  });

  group('SortControl', () {
    testWidgets('lists the options and reports the selection', (tester) async {
      (SortField, SortDirection)? chosen;
      await tester.pumpWidget(
        wrap(
          SortControl(
            field: SortField.featured,
            direction: SortDirection.ascending,
            onSelected: (field, direction) => chosen = (field, direction),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      expect(find.text('Price: low to high'), findsOneWidget);

      // warnIfMissed: the Text's center sits slightly outside the menu item's
      // InkWell hit area (same geometry quirk documented in shop_flow_test).
      await tester.tap(find.text('Price: low to high'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(chosen, (SortField.price, SortDirection.ascending));
    });
  });

  group('PriceText', () {
    testWidgets('formats the amount in the app currency and applies a color', (
      tester,
    ) async {
      // PriceText reads the display currency from SettingsCubit, so the
      // harness must provide it.
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => SettingsCubit(),
          child: wrap(PriceText(1299.5, color: Colors.red)),
        ),
      );

      expect(find.text(r'$1,299.50'), findsOneWidget);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('re-renders in the selected currency', (tester) async {
      final settingsCubit = SettingsCubit();
      addTearDown(settingsCubit.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: settingsCubit,
          child: wrap(PriceText(1299.5)),
        ),
      );
      expect(find.text(r'$1,299.50'), findsOneWidget);

      // Switching currency live-rebuilds the price.
      settingsCubit.setCurrency(Currency.eur);
      await tester.pumpAndSettle();
      expect(find.text('€1,299.50'), findsOneWidget);
    });
  });

  group('SurfaceCard', () {
    testWidgets('fires onTap when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(SurfaceCard(onTap: () => tapped = true, child: const Text('x'))),
      );

      await tester.tap(find.text('x'));
      expect(tapped, isTrue);
    });
  });

  group('CircleIcon', () {
    testWidgets('renders the icon', (tester) async {
      await tester.pumpWidget(wrap(CircleIcon(icon: Icons.check_rounded)));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('ProductImage', () {
    testWidgets('uses the stable hero tag for the product', (tester) async {
      await tester.pumpWidget(wrap(ProductImage(product: product)));
      await tester.pumpAndSettle();

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'product-image-1');
    });
  });

  group('BottomActionBar', () {
    testWidgets('renders above content, leading widget and the button', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BottomActionBar(
            above: const Text('Total \$10'),
            leading: const Icon(Icons.add),
            button: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock_outline),
              label: const Text('Checkout'),
            ),
          ),
        ),
      );

      expect(find.text('Total \$10'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('stretches the button to fill the bar width', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          BottomActionBar(
            button: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );

      // 16px padding on each side leaves ~468px for the button; an un-stretched
      // button would be only ~70px wide.
      expect(tester.getSize(find.byType(FilledButton)).width, closeTo(468, 4));
    });
  });
}
