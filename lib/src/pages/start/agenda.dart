import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class AgendaBody extends StatefulWidget {
  const AgendaBody({super.key});

  @override
  State<AgendaBody> createState() => _AgendaBodyState();
}

class _AgendaBodyState extends State<AgendaBody> {
  Future<List<AgendaItemSource>>? _agendaData;

  void _refreshAgendaData() {
    _agendaData = getAllAgendaSections(
      Preferences.of(context, .agenda).agendaFileJsons,
      Preferences.of(context, .accessibleDirs).accessibleDirs,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshAgendaData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshAgendaData());
        await _agendaData;
      },
      child: FutureBuilder(
        future: _agendaData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _RefreshableChildView(
              child: Center(
                child: Column(
                  mainAxisAlignment: .center,
                  spacing: 16,
                  children: [
                    const Icon(Icons.error),
                    Text(
                      snapshot.error?.toString() ??
                          AppLocalizations.of(context)!.errorUnknown,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return _RefreshableChildView(
              child: Center(
                child: Column(
                  mainAxisAlignment: .center,
                  spacing: 16,
                  children: [
                    const Icon(Icons.calendar_month),
                    Text(AppLocalizations.of(context)!.emptyAgendaMessage),
                  ],
                ),
              ),
            );
          }

          // The iterable is infinite in principle. Without any caching we have
          // to recompute from the zeroth item on every access.
          //
          // In principle if the cache is not bounded then this can blow up
          // memory if the user scrolls very far through an agenda with many
          // items, but testing on iOS shows negligible impact.
          final iter = CachingIterable(
            agendaItemsFromSources(snapshot.data!).iterator,
          );

          final timeFormat = DateFormat.Hm();
          final dateFormat = DateFormat.yMMMMEEEEd();
          final theme = Theme.of(context);
          return ListView.builder(
            itemBuilder: (context, index) {
              try {
                final (:section, :dataSource, :scheduledAt) = iter.elementAt(
                  index,
                );
                final result = ListTile(
                  leading: Text(timeFormat.format(scheduledAt)),
                  title: Text(
                    section.headline.title?.toPlainText() ??
                        section.headline.rawTitle ??
                        AppLocalizations.of(context)!.unknownAgendaTitle,
                  ),
                  titleAlignment: .center,
                  subtitle: Text(dataSource.name),
                  onTap: () => loadAndRememberFile(context, dataSource),
                );

                final needsHeader =
                    index == 0 ||
                    !iter
                        .elementAt(index - 1)
                        .scheduledAt
                        .isSameDayAs(scheduledAt);
                if (!needsHeader) return result;

                return Column(
                  crossAxisAlignment: .start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: theme.dividerColor,
                      width: .infinity,
                      child: Text(
                        dateFormat.format(scheduledAt).toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: .w500,
                        ),
                      ),
                    ),
                    result,
                  ],
                );
              } on RangeError {
                return null;
              }
            },
          );
        },
      ),
    );
  }
}

class _RefreshableChildView extends StatelessWidget {
  const _RefreshableChildView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }
}
