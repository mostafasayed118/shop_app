import 'package:e_commerce/ui/widgets/owned_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal host that exercises the mixin's toast convenience.
class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.message});

  final String message;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> with OwnedSnackBar<_ToastHost> {
  void _show() => showOwnedToast(widget.message);

  void _hide() => hideOwnedSnackBar();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: _show, child: const Text('show')),
          TextButton(onPressed: _hide, child: const Text('hide')),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('showOwnedToast surfaces the message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _ToastHost(message: 'Hello toast')),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.text('Hello toast'), findsOneWidget);

    // Flush the snackbar's auto-dismiss timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('hideOwnedSnackBar dismisses the toast', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _ToastHost(message: 'Hello toast')),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.text('Hello toast'), findsOneWidget);

    await tester.tap(find.text('hide'));
    await tester.pumpAndSettle();
    expect(find.text('Hello toast'), findsNothing);
  });
}
