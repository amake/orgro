import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/filter.dart';
import 'package:orgro/src/components/bottom.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/util.dart';

class MySearchDelegate {
  MySearchDelegate({
    required this.onQueryChanged,
    required this.onQuerySubmitted,
    required this.onFilterChanged,
    String? initialQuery,
    FilterData? initialFilter,
  })  : _searchController = TextEditingController(text: initialQuery),
        _selectedFilter =
            ValueNotifier(initialFilter ?? FilterData.defaults()) {
    _searchController.addListener(debounce(
      () => onQueryChanged(_searchController.text),
      const Duration(milliseconds: 500),
    ));
    _selectedFilter.addListener(() => onFilterChanged(_selectedFilter.value));
  }

  final void Function(String) onQueryChanged;
  final void Function(String) onQuerySubmitted;
  final void Function(FilterData) onFilterChanged;
  List<String> keywords = [];
  List<String> tags = [];
  List<String> priorities = [];
  List<OrgTodoStates> todoSettings = [];
  final ValueNotifier<FilterData> _selectedFilter;
  final ValueNotifier<bool> searchMode = ValueNotifier(false);
  final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  set query(String value) {
    _searchController.text = value;
    // Apply immediately because we debounce in the listener, and short queries
    // are swallowed, etc.
    onQuerySubmitted(value);
  }

  set filter(FilterData value) => _selectedFilter.value = value;

  Widget buildSearchField() => SearchField(
        _searchController,
        filterData: _selectedFilter,
        focusNode: _searchFocusNode,
        todoSettings: todoSettings,
        onClear: _clearSearchQuery,
        onSubmitted: onQuerySubmitted,
      );

  Widget buildBottomSheet(BuildContext context) {
    return BottomInputBar(
      child: FilterChipsInput(
        keywords: keywords,
        tags: tags,
        priorities: priorities,
        todoSettings: todoSettings,
        selectedFilter: _selectedFilter,
      ),
    );
  }

  void dispose() {
    _searchController.dispose();
    searchMode.dispose();
    _searchFocusNode.dispose();
    _selectedFilter.dispose();
  }

  void start(BuildContext context) {
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearch));
    searchMode.value = true;
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    searchMode.value = false;
  }

  void _clearSearchQuery() {
    _searchController.clear();
    // Apply immediately because we debounce in the listener
    onQuerySubmitted(_searchController.text);
    // It's somehow surprising to clear the filter here as well, so don't
  }

  bool get hasQuery =>
      _searchController.value.text.isNotEmpty ||
      _selectedFilter.value.isNotEmpty;

  String get queryString => _searchController.value.text;
}

class SearchField extends StatelessWidget {
  const SearchField(
    this._controller, {
    required this.filterData,
    required this.focusNode,
    required this.todoSettings,
    this.onClear,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController _controller;
  final FocusNode focusNode;
  final List<OrgTodoStates> todoSettings;
  final ValueNotifier<FilterData> filterData;
  final VoidCallback? onClear;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // All these theme gyrations are to try to match the default appearance of
    // regular text in the AppBar
    final theme = Theme.of(context);
    final style = DefaultTextStyle.of(context).style;
    final color = style.color?.withAlpha((0.7 * 255).round());
    final iconTheme = IconThemeData(color: color);
    return Theme(
      data: theme.copyWith(hintColor: color),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ValueListenableBuilder(
                  valueListenable: filterData,
                  builder: (context, filter, _) => Row(
                    children: [
                      ...[
                        SelectedFilterChips(
                          filter: filter,
                          todoSettings: todoSettings,
                          onChange: (value) => filterData.value = value,
                        ),
                        if (filter.isNotEmpty)
                          IconTheme.merge(
                            data: iconTheme,
                            child: const Icon(Icons.drag_indicator),
                          ),
                      ].separatedBy(const SizedBox(width: 8)),
                      ConstrainedBox(
                        constraints: filter.isNotEmpty
                            ? BoxConstraints.tightFor(
                                width: constraints.maxWidth -
                                    IconTheme.of(context).size!)
                            : constraints,
                        child: TextField(
                          autofocus: true,
                          focusNode: focusNode,
                          style: style,
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          cursorColor: theme.colorScheme.secondary,
                          onSubmitted: onSubmitted,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.hintTextSearch,
                            border: InputBorder.none,
                            prefixIcon: IconTheme.merge(
                              data: iconTheme,
                              child: const Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) =>
                value.text.isNotEmpty ? child! : const SizedBox.shrink(),
            child: IconTheme.merge(
              data: iconTheme,
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
            ),
          )
        ],
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
  List<SearchResultKey> _keys = [];
  late OrgControllerData _controller;

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = OrgController.of(context);
    if (!_inited) {
      _controller.searchResultKeys.addListener(_update);
      _inited = true;
    }
  }

  @override
  void dispose() {
    _controller.searchResultKeys.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final keys = _controller.searchResultKeys.value;
    final sortedKeys = List.of(keys)..sort((a, b) => a.compareByTopBound(b));
    setState(() {
      _i = sortedKeys.indexWhere((key) => key.currentState?.selected == true);
      _keys = sortedKeys;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        _DisablableMiniFloatingActionButton(
          heroTag: 'prevSearchHitFAB',
          onPressed: _keys.isEmpty ? null : () => _scrollToRelativeIndex(-1),
          child: const Icon(Icons.keyboard_arrow_up),
        ),
        GestureDetector(
          onTap: _keys.isEmpty ? null : () => _scrollToRelativeIndex(0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                _i == -1
                    ? AppLocalizations.of(context)!.searchHits(_keys.length)
                    : AppLocalizations.of(context)!
                        .searchResultSelection(_i + 1, _keys.length),
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
          onPressed: _keys.isEmpty ? null : () => _scrollToRelativeIndex(1),
          child: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  void _scrollToRelativeIndex(int relIdx) {
    // Empty selection special cases
    if (_i == -1) {
      // Don't "go to" empty selection
      if (relIdx == 0) return;
      // Wrap backwards from empty selection
      if (relIdx == -1) relIdx = 0;
    }
    if (_i >= 0 && _i < _keys.length) _keys[_i].currentState?.selected = false;
    final i = (_i + relIdx + _keys.length) % _keys.length;
    final key = _keys[i];
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
