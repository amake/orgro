import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class FilterChipsInput extends StatelessWidget {
  const FilterChipsInput({
    required this.keywords,
    required this.tags,
    required this.priorities,
    required this.selectedFilter,
    super.key,
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

class SelectedFilterChips extends StatelessWidget {
  const SelectedFilterChips({
    required this.filter,
    required this.onChange,
    super.key,
  });

  final FilterData filter;
  final void Function(FilterData) onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (filter.customFilter.isNotEmpty)
          _CustomChip(
            query: filter.customFilter,
            onDeleted: () => onChange(filter.copyWith(customFilter: '')),
          ),
        for (final keyword in filter.keywords)
          _KeywordChip(
            keyword,
            onDeleted: () => onChange(filter.copyWith(
                keywords: List.of(filter.keywords)..remove(keyword))),
          ),
        for (final priority in filter.priorities)
          _PriorityChip(
            priority,
            onDeleted: () => onChange(filter.copyWith(
                priorities: List.of(filter.priorities)..remove(priority))),
          ),
        for (final tag in filter.tags)
          _TagChip(
            tag,
            onDeleted: () => onChange(
                filter.copyWith(tags: List.of(filter.tags)..remove(tag))),
          ),
      ].separatedBy(const SizedBox(width: 8)).toList(growable: false),
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
