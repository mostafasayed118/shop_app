import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/status_view.dart';

/// Fallback for routes that don't exist or reference a product that isn't in
/// the catalogue (e.g. a stale web deep link). Reuses the app's shared
/// [StatusView] treatment; "Back to shop" resets navigation to the catalogue.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: StatusView(
        icon: Icons.search_off,
        title: 'Page not found',
        message: message,
        action: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Back to shop'),
        ),
      ),
    );
  }
}
