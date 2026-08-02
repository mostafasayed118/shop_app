import 'package:flutter/material.dart';

/// Text field with a clear (suffix) button, kept in sync with an externally
/// owned query string (e.g. a Cubit state or form controller).
///
/// The [query] is the source of truth: it seeds the field on creation and is
/// re-applied when it changes externally (e.g. a "Clear filters" action), so
/// the field never drifts from the state that filters the list.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.query,
    required this.onChanged,
    this.hintText = 'Search',
    this.padding = const EdgeInsets.fromLTRB(16, 12, 4, 4),
  });

  final String query;
  final ValueChanged<String> onChanged;
  final String hintText;
  final EdgeInsetsGeometry padding;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the query changes externally.
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    setState(() {}); // Refresh the clear (suffix) icon.
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      // The filled surface look, zero content padding and borderless shape all
      // come from the app's inputDecorationTheme.
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
}
