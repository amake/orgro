import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/preferences.dart';
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
      _searchQueryChanged,
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
  final ValueNotifier<FilterData> _selectedFilter;
  final ValueNotifier<bool> searchMode = ValueNotifier(false);
  final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  Widget buildSearchField() => SearchField(
        _searchController,
        filterData: _selectedFilter,
        focusNode: _searchFocusNode,
        onClear: _clearSearchQuery,
        onSubmitted: onQuerySubmitted,
      );

  Widget buildBottomSheet() => BottomSheet(
        enableDrag: false,
        showDragHandle: false,
        onClosing: () {
          // This should never happen
          debugPrint('Closing bottom sheet');
        },
        builder: (context) => _FilterChipsInput(
          keywords: keywords,
          tags: tags,
          priorities: priorities,
          selectedFilter: _selectedFilter,
        ),
      );

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
    // These don't debounce in the listener so we just assign
    _selectedFilter.value = FilterData.defaults();
  }

  void _searchQueryChanged() => onQueryChanged(_searchController.text);

  bool get hasQuery =>
      _searchController.value.text.isNotEmpty ||
      _selectedFilter.value.isNotEmpty;

  String get queryString => _searchController.value.text;
}

class _FilterChipsInput extends StatelessWidget {
  const _FilterChipsInput({
    required this.keywords,
    required this.tags,
    required this.priorities,
    required this.selectedFilter,
  });

  final List<String> keywords;
  final List<String> tags;
  final List<String> priorities;
  final ValueNotifier<FilterData> selectedFilter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedFilter,
      builder: (context, filter, _) {
        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (filter.customFilter.isEmpty)
                  _CustomChip(
                    label: AppLocalizations.of(context)!
                        .customFilterChipName
                        .toUpperCase(),
                    onPressed: () async {
                      final newQuery = await showDialog<String>(
                        context: context,
                        builder: (context) => const InputFilterQueryDialog(),
                      );
                      if (newQuery != null) {
                        selectedFilter.value =
                            filter.copyWith(customFilter: newQuery);
                      }
                    },
                    onLongPress:
                        Preferences.of(context).customFilterQueries.isNotEmpty
                            ? () async {
                                final newQuery = await showDialog<String>(
                                  context: context,
                                  builder: (context) =>
                                      const CustomFilterHistoryDialog(),
                                );
                                if (newQuery != null) {
                                  selectedFilter.value =
                                      filter.copyWith(customFilter: newQuery);
                                }
                              }
                            : null,
                  ),
                for (final keyword in keywords)
                  if (filter.keywords.isEmpty)
                    _KeywordChip(
                      keyword,
                      onPressed: () => selectedFilter.value = filter
                          .copyWith(keywords: [...filter.keywords, keyword]),
                    ),
                for (final priority in priorities)
                  if (filter.priorities.isEmpty)
                    _PriorityChip(
                      priority,
                      onPressed: () => selectedFilter.value = filter.copyWith(
                          priorities: [...filter.priorities, priority]),
                    ),
                for (final tag in tags)
                  if (!filter.tags.contains(tag))
                    _TagChip(
                      tag,
                      onPressed: () => selectedFilter.value =
                          filter.copyWith(tags: [...filter.tags, tag]),
                    ),
              ].separatedBy(const SizedBox(width: 8)).toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField(
    this._controller, {
    required this.filterData,
    required this.focusNode,
    this.onClear,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController _controller;
  final FocusNode focusNode;
  final ValueNotifier<FilterData> filterData;
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
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ValueListenableBuilder(
            valueListenable: filterData,
            builder: (context, filter, _) => Row(
              children: [
                ...[
                  if (filter.customFilter.isNotEmpty)
                    _CustomChip(
                      query: filter.customFilter,
                      onDeleted: () =>
                          filterData.value = filter.copyWith(customFilter: ''),
                    ),
                  for (final keyword in filter.keywords)
                    _KeywordChip(
                      keyword,
                      onDeleted: () => filterData.value = filter.copyWith(
                          keywords: List.of(filter.keywords)..remove(keyword)),
                    ),
                  for (final priority in filter.priorities)
                    _PriorityChip(
                      priority,
                      onDeleted: () => filterData.value = filter.copyWith(
                          priorities: List.of(filter.priorities)
                            ..remove(priority)),
                    ),
                  for (final tag in filter.tags)
                    _TagChip(
                      tag,
                      onDeleted: () => filterData.value = filter.copyWith(
                          tags: List.of(filter.tags)..remove(tag)),
                    ),
                  if (filter.isNotEmpty) const Icon(Icons.drag_indicator),
                ].separatedBy(const SizedBox(width: 8)),
                ConstrainedBox(
                  constraints: constraints.copyWith(
                      maxWidth: filter.isNotEmpty
                          ? constraints.maxWidth - IconTheme.of(context).size!
                          : constraints.maxWidth),
                  child: TextField(
                    autofocus: true,
                    focusNode: focusNode,
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
                              value.text.isNotEmpty
                                  ? child!
                                  : const SizedBox.shrink(),
                          child: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: onClear,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip(this.keyword, {this.onPressed, this.onDeleted});
  final String keyword;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.check),
      label: Text(keyword),
      onPressed: onPressed,
      onDeleted: onDeleted,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.tag, {this.onPressed, this.onDeleted});
  final String tag;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.label),
      label: Text(tag),
      onPressed: onPressed,
      onDeleted: onDeleted,
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip(this.priority, {this.onPressed, this.onDeleted});
  final String priority;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.tag),
      label: Text(priority),
      onPressed: onPressed,
      onDeleted: onDeleted,
    );
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({
    this.label,
    this.query,
    this.onPressed,
    this.onDeleted,
    this.onLongPress,
  }) : assert(label != null || query != null);

  final String? query;
  final String? label;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: InputChip(
        avatar: const Icon(Icons.edit),
        label: label != null
            ? Text(label!)
            : ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width / 4),
                child: Text(query!)),
        onPressed: onPressed,
        onDeleted: onDeleted,
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
