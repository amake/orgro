import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/components/layout.dart';
import 'package:orgro/src/components/lifecycle.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/util.dart';

class AgendaBody extends StatefulWidget {
  const AgendaBody({super.key});

  @override
  State<AgendaBody> createState() => _AgendaBodyState();
}

class _AgendaBodyState extends State<AgendaBody>
    with AutomaticKeepAliveClientMixin {
  @override
  final wantKeepAlive = true;

  Future<List<AgendaItemSource>>? _agendaData;
  Future<void>? _notificationsUpdate;

  var today = DateTime.now().startOfDay();

  void _refresh() {
    final (agendaFileJsons, notificationsEnabled) = (() {
      final prefs = Preferences.of(context, .agenda);
      return (prefs.agendaFileJsons, prefs.agendaOSNotificationsEnabled);
    })();
    final accessibleDirs = Preferences.of(
      context,
      .accessibleDirs,
    ).accessibleDirs;
    final localizations = AppLocalizations.of(context)!;
    final parsedFiles = Future.wait(
      agendaFileJsons.map((e) => parseAgendaFileJson(e, accessibleDirs)),
    ).then((files) => files.whereType<ParsedOrgFileInfo>());
    _agendaData = parsedFiles.then(
      (files) => files
          .expand((f) => getAgendaSections(f, now: today))
          .toList(growable: false),
    );
    _notificationsUpdate = parsedFiles.then((files) async {
      if (!notificationsEnabled) return;

      for (final file in files) {
        await setNotificationsForDocument((
          file.dataSource,
          file.doc,
          localizations,
        ));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AppLifecycle(
      onStateChange: (state) {
        if (state == .resumed) {
          final newToday = DateTime.now().startOfDay();
          if (!newToday.isSameDayAs(today)) {
            setState(() {
              today = newToday;
              _refresh();
            });
          }
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _refresh());
          await _agendaData;
          await _notificationsUpdate;
        },
        child: FutureBuilder(
          future: _agendaData,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const _EmptyView();
            }

            // The iterable is infinite in principle. Without any caching we
            // have to recompute from the zeroth item on every access.
            //
            // In principle if the cache is not bounded then this can blow up
            // memory if the user scrolls very far through an agenda with many
            // items, but testing on iOS shows negligible impact.
            final iter = CachingIterable(
              agendaItemsFromSources(snapshot.data!, now: today).iterator,
            );

            // The time format is always in 24-hour format, regardless of
            // locale.
            final timeFormat = DateFormat.Hm();
            final timeWidth = renderedBounds(
              context,
              const BoxConstraints(),
              Text.rich(
                TextSpan(text: timeFormat.format(DateTime(0))),
                style: _AgendaTime._timeStyle,
              ),
            ).toRect().width;
            final locale = AppLocalizations.of(context)!.localeName;
            final dateFormat = DateFormat.yMMMMEEEEd(locale);
            final theme = Theme.of(context);
            return ListView.builder(
              restorationId: 'agenda_list',
              itemBuilder: (context, index) {
                final AgendaItem item;
                try {
                  item = iter.elementAt(index);
                } on RangeError {
                  return null;
                }
                final (:section, :dataSource, scheduledAt: agendaSpan) = item;

                final title =
                    section.headline.title?.toPlainText() ??
                    section.headline.rawTitle ??
                    AppLocalizations.of(context)!.unknownAgendaTitle;
                final result = ConstrainForWideScreen(
                  child: ListTile(
                    leading: _AgendaTime(
                      agendaSpan: agendaSpan,
                      timeFormat: timeFormat,
                      iconWidth: timeWidth,
                    ),
                    title: Text(title),
                    titleAlignment: .center,
                    subtitle: Text(dataSource.name),
                    onTap: () => _openAgendaItem(section, dataSource),
                  ),
                );

                final needsHeader =
                    index == 0 ||
                    !iter
                        .elementAt(index - 1)
                        .scheduledAt
                        .$1
                        .isSameDayAs(agendaSpan.$1);
                if (!needsHeader) return result;

                return Column(
                  crossAxisAlignment: .start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: theme.dividerColor,
                      width: .infinity,
                      child: ConstrainForWideScreen(
                        child: SizedBox(
                          width: .infinity,
                          child: Text(
                            dateFormat.format(agendaSpan.$1).toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: .w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    result,
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openAgendaItem(OrgTree section, DataSource dataSource) {
    final target = section.targetForSection;
    final AfterOpenCallback? afterOpen = target == null
        ? null
        : (state) => OrgLocator.of(state.context)!.jumpToSection(target);

    switch (dataSource) {
      case NativeDataSource():
        loadAndRememberFile(context, dataSource, afterOpen: afterOpen);
      default:
        loadDocument(context, dataSource, afterOpen: afterOpen);
    }
  }
}

class _AgendaTime extends StatelessWidget {
  const _AgendaTime({
    required this.agendaSpan,
    required this.timeFormat,
    required this.iconWidth,
  });

  final ChunkedAgendaSpan agendaSpan;
  final DateFormat timeFormat;
  final double iconWidth;

  static TextStyle get _timeStyle =>
      const TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

  @override
  Widget build(BuildContext context) {
    final (start, end, chunkIdx, last) = agendaSpan;

    if (start.isAtSameMomentAs(end)) {
      return Text(timeFormat.format(start), style: _timeStyle);
    }

    if (start.isStartOfDay() && end.isStartOfDay()) {
      return SizedBox(
        width: iconWidth,
        child: const Icon(Icons.calendar_today),
      );
    }

    if (chunkIdx == 0 && !last && end.isStartOfDay()) {
      return Column(
        mainAxisAlignment: .center,
        children: [
          Text(timeFormat.format(start), style: _timeStyle),
          const Text('|'),
        ],
      );
    }

    if (chunkIdx > 0 && last && start.isStartOfDay()) {
      return Column(
        mainAxisAlignment: .center,
        children: [
          const Text('|'),
          Text(timeFormat.format(end), style: _timeStyle),
        ],
      );
    }

    return Column(
      mainAxisAlignment: .center,
      children: [
        Text(timeFormat.format(start), style: _timeStyle),
        Text(timeFormat.format(end), style: _timeStyle),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return _RefreshableChildView(
      child: Center(
        child: Column(
          mainAxisAlignment: .center,
          spacing: 16,
          children: [
            const Icon(Icons.error),
            Text(
              error?.toString() ?? AppLocalizations.of(context)!.errorUnknown,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
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
