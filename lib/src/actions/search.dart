import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/util.dart';

class MySearchDelegate {
  MySearchDelegate({
    required this.onQueryChanged,
    required this.onQuerySubmitted,
    String? initialQuery,
  }) : _searchController = TextEditingController(text: initialQuery) {
    _searchController.addListener(_searchQueryChanged);
  }

  final void Function(String) onQueryChanged;
  final void Function(String) onQuerySubmitted;
  final ValueNotifier<bool> searchMode = ValueNotifier(false);
  final TextEditingController _searchController;

  Widget buildSearchField() => SearchField(
        _searchController,
        onClear: _clearSearchQuery,
        onSubmitted: onQuerySubmitted,
      );

  void dispose() {
    _searchController.dispose();
    searchMode.dispose();
  }

  void start(BuildContext context) {
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearch));
    searchMode.value = true;
  }

  void _stopSearch() {
    searchMode.value = false;
  }

  void _clearSearchQuery() {
    _searchController.clear();
    onQuerySubmitted(_searchController.text);
  }

  void _searchQueryChanged() => onQueryChanged(_searchController.text);

  bool get hasQuery => _searchController.value.text.isNotEmpty;

  String get queryString => _searchController.value.text;
}

class SearchButton extends StatelessWidget {
  const SearchButton({
    required this.hasQuery,
    required this.onPressed,
    super.key,
  });
  final VoidCallback onPressed;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onPressed,
        ),
        // Badge indicating an active query. The size and positioning is
        // manually adjusted to match the icon it adorns. The icon is assumed to
        // take up an a kMinInteractiveDimension × kMinInteractiveDimension
        // area.
        Positioned(
          top: kMinInteractiveDimension / 3,
          right: kMinInteractiveDimension / 3,
          child: Visibility(
            visible: hasQuery,
            child: Container(
              height: kMinInteractiveDimension / 6,
              width: kMinInteractiveDimension / 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField(
    this._controller, {
    this.onClear,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController _controller;
  final VoidCallback? onClear;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // All these theme gyrations are to try to match the default appearance of
    // regular text in the AppBar
    final theme = Theme.of(context);
    final style = DefaultTextStyle.of(context).style;
    final color = style.color?.withOpacity(0.7);
    final iconTheme = IconThemeData(color: color);
    return Theme(
      data: theme.copyWith(hintColor: color),
      child: TextField(
        autofocus: true,
        style: style,
        controller: _controller,
        textInputAction: TextInputAction.search,
        cursorColor: theme.colorScheme.secondary,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.hintTextSearch,
          border: InputBorder.none,
          prefixIcon: IconTheme.merge(
            data: iconTheme,
            child: const Icon(Icons.search),
          ),
          suffixIcon: IconTheme.merge(
            data: iconTheme,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) =>
                  value.text.isNotEmpty ? child! : const SizedBox.shrink(),
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchResultsNavigation extends StatefulWidget {
  const SearchResultsNavigation({super.key});

  @override
  State<SearchResultsNavigation> createState() =>
      _SearchResultsNavigationState();
}

class _SearchResultsNavigationState extends State<SearchResultsNavigation> {
  int _i = -1;

  @override
  Widget build(BuildContext context) {
    final controller = OrgController.of(context);
    return ValueListenableBuilder(
      valueListenable: controller.searchResultKeys,
      builder: (context, value, child) {
        if (value.isEmpty) _resetIndex();
        return Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _DisablableMiniFloatingActionButton(
              heroTag: 'prevSearchHitFAB',
              onPressed:
                  value.isEmpty ? null : () => _scrollToRelativeIndex(-1),
              child: const Icon(Icons.keyboard_arrow_up),
            ),
            GestureDetector(
              onTap: value.isEmpty ? null : () => _scrollToRelativeIndex(0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _i == -1
                        ? AppLocalizations.of(context)!.searchHits(value.length)
                        : AppLocalizations.of(context)!
                            .searchResultSelection(_i + 1, value.length),
                    textAlign: TextAlign.center,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            _DisablableMiniFloatingActionButton(
              heroTag: 'nextSearchHitFAB',
              onPressed: value.isEmpty ? null : () => _scrollToRelativeIndex(1),
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ],
        );
      },
    );
  }

  void _resetIndex() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() => _i = -1);
    });
  }

  List<SearchResultKey> _sortedKeys(BuildContext context) {
    final keys = List.of(OrgController.of(context).searchResultKeys.value);
    keys.sort((a, b) => a.compareByTopBound(b));
    return keys;
  }

  void _scrollToRelativeIndex(int relIdx) {
    final keys = _sortedKeys(context);
    if (_i >= 0 && _i < keys.length) keys[_i].currentState?.selected = false;
    final i = (_i + relIdx + keys.length) % keys.length;
    final key = keys[i];
    key.currentState?.selected = true;
    _scrollTo(key);
    setState(() => _i = i);
  }

  void _scrollTo(SearchResultKey key) {
    debugPrint('Scrolling to $key');
    final keyContext = key.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 100),
      );
    }
  }
}

class _DisablableMiniFloatingActionButton extends StatelessWidget {
  const _DisablableMiniFloatingActionButton({
    this.onPressed,
    this.heroTag,
    this.child,
  });

  final VoidCallback? onPressed;
  final Widget? child;
  final Object? heroTag;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      backgroundColor: _backgroundColor(context),
      mini: true,
      child: child,
    );
  }

  Color? _backgroundColor(BuildContext context) => _enabled
      ? null // default
      : Theme.of(context).disabledColor;
}
