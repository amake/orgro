import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MySearchDelegate {
  MySearchDelegate({@required this.onQueryChanged})
      : assert(onQueryChanged != null) {
    _searchController.addListener(_searchQueryChanged);
  }

  final Function(Pattern) onQueryChanged;
  final ValueNotifier<bool> searchMode = ValueNotifier(false);
  final _searchController = TextEditingController();

  Widget buildSearchField() => SearchField(
        _searchController,
        onClear: _clearSearchQuery,
      );

  void dispose() {
    _searchController.dispose();
  }

  void start(BuildContext context) {
    ModalRoute.of(context)
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearch));
    searchMode.value = true;
  }

  void _stopSearch() {
    _clearSearchQuery();
    searchMode.value = false;
  }

  void _clearSearchQuery() => _searchController.clear();

  void _searchQueryChanged() {
    final pattern = RegExp(
      RegExp.escape(_searchController.text),
      unicode: true,
      caseSensitive: false,
    );
    onQueryChanged(pattern);
  }
}

class SearchField extends StatelessWidget {
  const SearchField(
    this._controller, {
    this.onClear,
    Key key,
  }) : super(key: key);
  final TextEditingController _controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    // All these theme gyrations are to try to match the default appearance of
    // regular text in the AppBar
    final theme = Theme.of(context);
    final style = DefaultTextStyle.of(context).style;
    final color = style.color.withOpacity(0.7);
    final iconTheme = IconThemeData(color: color);
    return Theme(
      data: theme.copyWith(
        primaryColor: color,
        accentColor: color,
        hintColor: color,
        disabledColor: color,
        cursorColor: theme.accentColor,
        colorScheme: theme.colorScheme.copyWith(onSurface: color),
      ),
      child: TextField(
        autofocus: true,
        style: style,
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search...',
          border: InputBorder.none,
          prefixIcon: IconTheme.merge(
            data: iconTheme,
            child: const Icon(Icons.search),
          ),
          suffixIcon: IconTheme.merge(
            data: iconTheme,
            child: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
          ),
        ),
      ),
    );
  }
}
