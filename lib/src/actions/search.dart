import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/util.dart';

class MySearchDelegate {
  MySearchDelegate({
    required this.onQueryChanged,
    required this.onQuerySubmitted,
    required this.onKeywordsChanged,
    required this.onTagsChanged,
    required this.onPrioritiesChanged,
    String? initialQuery,
  }) : _searchController = TextEditingController(text: initialQuery) {
    _searchController.addListener(debounce(
      _searchQueryChanged,
      const Duration(milliseconds: 500),
    ));
    _selectedKeywords
        .addListener(() => onKeywordsChanged(_selectedKeywords.value));
    _selectedTags.addListener(() => onTagsChanged(_selectedTags.value));
    _selectedPriorities
        .addListener(() => onPrioritiesChanged(_selectedPriorities.value));
  }

  final void Function(String) onQueryChanged;
  final void Function(String) onQuerySubmitted;
  final void Function(List<String>) onKeywordsChanged;
  final void Function(List<String>) onTagsChanged;
  final void Function(List<String>) onPrioritiesChanged;
  List<String> keywords = [];
  List<String> tags = [];
  List<String> priorities = [];
  final ValueNotifier<List<String>> _selectedKeywords = ValueNotifier([]);
  final ValueNotifier<List<String>> _selectedTags = ValueNotifier([]);
  final ValueNotifier<List<String>> _selectedPriorities = ValueNotifier([]);
  final ValueNotifier<bool> searchMode = ValueNotifier(false);
  final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  Widget buildSearchField() => SearchField(
        _searchController,
        keywords: _selectedKeywords,
        tags: _selectedTags,
        priorities: _selectedPriorities,
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
          selectedKeywords: _selectedKeywords,
          selectedTags: _selectedTags,
          selectedPriorities: _selectedPriorities,
        ),
      );

  void dispose() {
    _searchController.dispose();
    searchMode.dispose();
    _searchFocusNode.dispose();
    _selectedKeywords.dispose();
    _selectedTags.dispose();
    _selectedPriorities.dispose();
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
    _selectedKeywords.value = [];
    _selectedTags.value = [];
    _selectedPriorities.value = [];
  }

  void _searchQueryChanged() => onQueryChanged(_searchController.text);

  bool get hasQuery =>
      _searchController.value.text.isNotEmpty ||
      _selectedKeywords.value.isNotEmpty ||
      _selectedTags.value.isNotEmpty ||
      _selectedPriorities.value.isNotEmpty;

  String get queryString => _searchController.value.text;
}

class _FilterChipsInput extends StatelessWidget {
  const _FilterChipsInput({
    required this.keywords,
    required this.tags,
    required this.priorities,
    required this.selectedKeywords,
    required this.selectedTags,
    required this.selectedPriorities,
  });

  final List<String> keywords;
  final List<String> tags;
  final List<String> priorities;
  final ValueNotifier<List<String>> selectedKeywords;
  final ValueNotifier<List<String>> selectedTags;
  final ValueNotifier<List<String>> selectedPriorities;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedKeywords,
      builder: (context, selectedKeywordsVal, _) {
        return ValueListenableBuilder(
          valueListenable: selectedTags,
          builder: (context, selectedTagsVal, _) => ValueListenableBuilder(
            valueListenable: selectedPriorities,
            builder: (context, selectedPrioritiesVal, _) => SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    for (final keyword in keywords)
                      if (selectedKeywordsVal.isEmpty)
                        _KeywordChip(
                          keyword,
                          onPressed: () => selectedKeywords.value = [
                            ...selectedKeywordsVal,
                            keyword
                          ],
                        ),
                    for (final priority in priorities)
                      if (selectedPrioritiesVal.isEmpty)
                        _PriorityChip(
                          priority,
                          onPressed: () => selectedPriorities.value = [
                            ...selectedPrioritiesVal,
                            priority
                          ],
                        ),
                    for (final tag in tags)
                      if (!selectedTagsVal.contains(tag))
                        _TagChip(
                          tag,
                          onPressed: () =>
                              selectedTags.value = [...selectedTagsVal, tag],
                        ),
                  ]
                      .separatedBy(const SizedBox(width: 8))
                      .toList(growable: false),
                ),
              ),
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
    required this.keywords,
    required this.tags,
    required this.priorities,
    required this.focusNode,
    this.onClear,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController _controller;
  final FocusNode focusNode;
  final ValueNotifier<List<String>> keywords;
  final ValueNotifier<List<String>> tags;
  final ValueNotifier<List<String>> priorities;
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
            valueListenable: keywords,
            builder: (context, keywordsVal, _) => ValueListenableBuilder(
              valueListenable: tags,
              builder: (context, tagsVal, _) => ValueListenableBuilder(
                valueListenable: priorities,
                builder: (context, prioritiesVal, _) => Row(
                  children: [
                    ...[
                      for (final keyword in keywordsVal)
                        _KeywordChip(
                          keyword,
                          onDeleted: () => keywords.value = List.of(keywordsVal)
                            ..remove(keyword),
                        ),
                    ].separatedBy(const SizedBox(width: 8)),
                    ...[
                      for (final priority in prioritiesVal)
                        _PriorityChip(
                          priority,
                          onDeleted: () => priorities.value =
                              List.of(prioritiesVal)..remove(priority),
                        ),
                    ].separatedBy(const SizedBox(width: 8)),
                    ...[
                      for (final tag in tagsVal)
                        _TagChip(
                          tag,
                          onDeleted: () =>
                              tags.value = List.of(tagsVal)..remove(tag),
                        ),
                    ].separatedBy(const SizedBox(width: 8)),
                    if (keywordsVal.isNotEmpty ||
                        tagsVal.isNotEmpty ||
                        prioritiesVal.isNotEmpty)
                      const Icon(Icons.drag_indicator),
                    ConstrainedBox(
                      constraints: constraints.copyWith(
                          maxWidth: keywordsVal.isNotEmpty ||
                                  tagsVal.isNotEmpty ||
                                  prioritiesVal.isNotEmpty
                              ? constraints.maxWidth -
                                  IconTheme.of(context).size!
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
                          hintText:
                              AppLocalizations.of(context)!.hintTextSearch,
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
