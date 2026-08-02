import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-bar gear icon that opens the settings screen.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/settings'),
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
