import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/theme/theme_cubit.dart';

/// App-bar theme toggle. The icon mirrors the *current* [ThemeMode] — sun
/// (light), moon (dark), or a brightness-auto glyph (following the system) —
/// and tapping cycles light → dark → system, so a pinned theme can always be
/// undone. The choice is persisted by [ThemeCubit].
///
/// Requires a [ThemeCubit] above it (provided by `ShopApp`).
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.light => (Icons.light_mode_outlined, 'Light mode'),
          ThemeMode.dark => (Icons.dark_mode_outlined, 'Dark mode'),
          ThemeMode.system => (Icons.brightness_auto_outlined, 'Follow system'),
        };
        return IconButton(
          onPressed: () => context.read<ThemeCubit>().cycleThemeMode(),
          tooltip: tooltip,
          icon: Icon(icon),
        );
      },
    );
  }
}
