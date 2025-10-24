import 'package:flutter/foundation.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/statistics.dart';

extension NarrowHandler on DocumentPageState {
  Future<void> handleInitialTarget(String? target) async {
    if (target == null || target.isEmpty) return;

    // The target may be:
    // - *section
    // - #custom-id
    // - /regexp/
    // - named target
    // - 42 (line number)
    // - id:some-uuid
    // - id:some-uuid::$SEARCH_OPTION
    //   - SEARCH_OPTION can be any of the above except id:some-uuid
    //
    // https://orgmode.org/manual/Search-Options.html

    // TODO(aaron): This logic is pretty similar to OrgEvents.dispatchLinkTap;
    // maybe we can consolidate it.

    try {
      final fileLink = OrgFileLink.parse(target);
      assert(fileLink.scheme == 'id:');
      final section = OrgController.of(context).sectionWithId(fileLink.body);
      if (section != null) {
        // We may have an id: link with search option e.g. in the case of
        // opening an id: link pointing to another file.
        await doNarrow(section, searchOption: fileLink.extra);
      } else {
        // It was an id: link but we couldn't find the section
        debugPrint('No section with id: ${fileLink.body}');
        showErrorSnackBar(
          context,
          AppLocalizations.of(context)!.errorSectionNotFound(fileLink.body),
        );
      }
      return;
    } catch (e) {
      // Not an id: link
    }

    if (!mounted) return;

    try {
      final section = OrgController.of(context).sectionForTarget(target);
      if (section != null) {
        await doNarrow(section);
      } else {
        // It was a section query but we couldn't find the section
        debugPrint('No section for target: $target');
        showErrorSnackBar(
          context,
          AppLocalizations.of(context)!.errorSectionNotFound(target),
        );
      }
      return;
    } catch (e) {
      // Not a section target
    }

    if (!mounted) return;

    final handled = await OrgLocator.of(context)!.jumpToSearchOption(target);
    if (handled || !mounted) return;

    if (isLineNumberSearch(target) || isRegexpSearch(target)) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.errorUnsupportedSearchOption(target),
      );
      return;
    }
    // Last resort: handle as search
    searchDelegate.query = SearchQuery(target, QueryType.plain);
    searchDelegate.start(context);
  }

  void ensureOpenOnNarrow() {
    if (widget.root) return;
    final doc = DocumentProvider.of(context).doc;
    OrgController.of(context).setVisibilityOf(
      doc,
      (state) => switch (state) {
        OrgVisibilityState.folded => OrgVisibilityState.children,
        _ => state,
      },
    );
  }

  Future<void> doNarrow(OrgTree section, {String? searchOption}) async {
    final docProvider = DocumentProvider.of(context);
    final doc = docProvider.doc;
    if (section == doc) {
      debugPrint('Suppressing narrow to currently open document');
      await handleInitialTarget(searchOption);
      return;
    }
    final restorationTarget = _targetForSection(section);
    if (restorationTarget != null) {
      bucket!.write(kRestoreNarrowTargetKey, restorationTarget);
    }
    final newSection = await narrow(
      context,
      docProvider.dataSource,
      section,
      searchOption,
      widget.layer + 1,
    );
    bucket!.remove<String>(kRestoreNarrowTargetKey);
    if (newSection == null || identical(newSection, section)) {
      return;
    }
    try {
      final newDoc = _applyNarrowResult(before: section, after: newSection);
      if (newDoc != null) await updateDocument(newDoc as OrgTree);
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  String? _targetForSection(OrgTree section) {
    final id = section.ids.firstOrNull;
    if (id != null) {
      return 'id:$id';
    }
    final customId = section.customIds.firstOrNull;
    if (customId != null) {
      return '#$customId';
    }
    final title = section is OrgSection ? section.headline.rawTitle : null;
    if (title != null) {
      return '*$title';
    }
    return null;
  }

  OrgNode? _applyNarrowResult({
    required OrgTree before,
    required OrgTree after,
  }) {
    final doc = DocumentProvider.of(context).doc;
    switch (after) {
      case OrgSection():
        var newDoc = doc.editNode(before)!.replace(after).commit() as OrgTree;
        newDoc = recalculateHeadlineStats(newDoc, after.headline);
        return newDoc;
      case OrgDocument():
        // If the narrowed section was edited, an OrgDocument will come back.
        //
        // The document may be empty:
        if (after.content == null && after.sections.isEmpty) {
          return null;
        }
        OrgSection toReplace;
        Iterable<OrgSection> toInsert;
        if (after.content != null) {
          // The document may have leading content. The expected thing if
          // editing plain text would be to append it to the previous section,
          // but that's pretty annoying to do with zippers, so instead we wrap
          // it in a section just so it's not lost.
          toInsert = after.sections;
          final headline = AppLocalizations.of(context)!.editInsertedHeadline;
          final stars =
              toInsert.firstOrNull?.headline.stars ??
              (before is OrgSection
                  ? before.headline.stars
                  : (value: '*', trailing: ' '));
          toReplace = OrgSection(
            OrgHeadline(
              stars,
              null,
              null,
              OrgContent([OrgPlainText(headline)]),
              headline,
              null,
              '\n',
            ),
            after.content!,
          );
        } else {
          // If there is no leading content then we can just insert all the
          // sections. Note that if the sections' levels have been changed then
          // the resulting document could be one that is impossible to obtain
          // from parsing (i.e. improper nesting). This is hard to fix and at
          // the moment doesn't seem to cause any problems other than surprising
          // folding/unfolding behavior, so we just let it be.
          toReplace = after.sections.first;
          toInsert = after.sections.skip(1);
        }
        var zipper = doc.editNode(before)!.replace(toReplace);
        for (final newSec in toInsert) {
          zipper = zipper.insertRight(newSec);
        }
        final newDoc = zipper.commit();
        OrgController.of(context).adaptVisibility(
          newDoc as OrgTree,
          defaultState: OrgVisibilityState.children,
        );
        return newDoc;
      default:
        throw Exception('Unexpected section type: $after');
    }
  }
}
