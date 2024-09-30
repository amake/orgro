import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/pages/document/links.dart';
import 'package:orgro/src/util.dart';
import 'package:petit_bibtex/bibtex.dart';

extension CitationHandler on DocumentPageState {
  Future<bool> openCitation(OrgCitation citation) async {
    final doc = DocumentProvider.of(context).doc;
    final bibFiles = extractBibliograpies(doc);

    if (bibFiles.isEmpty) {
      showErrorSnackBar(context,
          AppLocalizations.of(context)!.snackbarMessageBibliographiesNotFound);
      return false;
    }

    final keys = citation.getKeys().unique();
    if (keys.isEmpty) {
      // This should never happen, as the parser should not recognize an
      // OrgCitation without at least one valid key
      showErrorSnackBar(context,
          AppLocalizations.of(context)!.snackbarMessageCitationKeysNotFound);
      return false;
    }

    final dataSource = DocumentProvider.of(context).dataSource;
    if (dataSource.needsToResolveParent) {
      showDirectoryPermissionsSnackBar(context);
      return false;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      ),
    );

    final entries = await _findBibTeXEntries(bibFiles, keys, dataSource);

    if (!mounted) return false;

    Navigator.pop(context);

    if (entries.isEmpty) {
      showErrorSnackBar(context,
          AppLocalizations.of(context)!.snackbarMessageCitationsNotFound);
      return false;
    }

    final notFound = keys
        .where((key) => !entries.any((entry) => entry.key == key))
        .toList(growable: false);

    if (notFound.isNotEmpty) {
      showErrorSnackBar(
          context,
          AppLocalizations.of(context)!
              .snackbarMessageSomeCitationsNotFound(notFound.join(', ')));
    }

    await showDialog<void>(
      context: context,
      builder: (context) => CitationsDialog(entries: entries),
    );

    return true;
  }

  Future<List<BibTeXEntry>> _findBibTeXEntries(
    Iterable<String> bibFiles,
    Iterable<String> keys,
    DataSource dataSource,
  ) async {
    final results = <BibTeXEntry>[];

    for (final bibFile in bibFiles) {
      try {
        final resolved = await dataSource.resolveRelative(bibFile);
        final content = await resolved.content;
        final entries = BibTeXDefinition().build().parse(content).value
            as List<BibTeXEntry>;
        results.addAll(entries.where((e) => keys.contains(e.key)));
      } catch (e, s) {
        logError(e, s);
        if (mounted) showErrorSnackBar(context, e);
      }
    }

    return results;
  }
}

List<String> extractBibliograpies(
  OrgTree tree,
) {
  final results = <String>[];
  tree.visit<OrgMeta>((meta) {
    if (meta.keyword.toLowerCase() == '#+bibliography:') {
      final trailing = meta.trailing.trim();
      final bibFile = trailing.startsWith('"') && trailing.endsWith('"')
          ? trailing.substring(1, trailing.length - 1)
          : trailing;
      results.add(bibFile);
    }
    return true;
  });
  return results;
}

extension EntryPresentation on BibTeXEntry {
  String? getPrettyValue(String? key) {
    final value = fields[key];
    if (value == null) return null;
    var result = value.replaceAll(RegExp(r'\s+'), ' ');
    while (true) {
      final trimmed = result
          .trimPrefSuff('"', '"')
          .trimPrefSuff('{', '}')
          .trimPrefSuff(r'\url{', '}');
      if (trimmed == result) break;
      result = trimmed;
    }
    if (key == 'pages') {
      result = result.contains('-') || result.contains(',')
          ? 'pp. ${result.replaceAll('--', '–')}'
          : 'p. $result';
    }
    if (key == 'volume') result = 'Vol. $result';
    if (key == 'number') result = 'No. $result';
    if (key == 'month') result = _expandMonth(result);
    if (key == 'doi' && Uri.tryParse(result)?.scheme.isEmpty == true) {
      result = 'doi:$result';
    }
    result = result.replaceAllMapped(
        RegExp(r'\{([^}]+)}'), (m) => m.group(1) ?? m.group(0)!);
    return result;
  }

  Uri? getUrl() {
    final rawUrl = getPrettyValue('url') ??
        getPrettyValue('doi') ??
        getPrettyValue('howpublished');
    if (rawUrl == null) return null;

    final url = Uri.tryParse(rawUrl);
    if (url == null) return null;

    return switch (url.scheme) {
      'doi' => url.replace(scheme: 'https', host: 'doi.org'),
      '' => null,
      _ => url,
    };
  }

  String getDetails() {
    final detailValues = fields.keys
        .where((key) => key != 'title')
        .map(getPrettyValue)
        .where((value) {
      if (value == null) return false;
      final asUri = Uri.tryParse(value);
      if (asUri == null) return true;
      return asUri.scheme.isEmpty || asUri.scheme == 'doi';
    });
    return detailValues.join(' • ');
  }
}

String _expandMonth(String m) => switch (m.toLowerCase()) {
      'jan' => 'January',
      'feb' => 'February',
      'mar' => 'March',
      'apr' => 'April',
      'may' => 'May',
      'jun' => 'June',
      'jul' => 'July',
      'aug' => 'August',
      'sep' => 'September',
      'oct' => 'October',
      'nov' => 'November',
      'dec' => 'December',
      _ => m,
    };
