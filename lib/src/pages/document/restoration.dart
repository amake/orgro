import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/document/document.dart';

extension RestorationUtils on DocumentPageState {
  Future<void> restoreDocument() async {
    final dirtyDocMarkup = bucket!.read<String>(kRestoreDirtyDocumentKey);
    if (dirtyDocMarkup == null) return;

    try {
      final newDoc = await parse(dirtyDocMarkup);
      if (!mounted) return;
      OrgController.of(context).adaptVisibility(newDoc);
      await updateDocument(newDoc);
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  void restoreSearchState() {
    final searchQuery = bucket!.read<String>(kRestoreSearchQueryKey);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      searchDelegate.query = searchQuery;
    }
    final searchFilterJson = bucket!.read<Map<Object?, Object?>>(
      kRestoreSearchFilterKey,
    );
    final searchFilter = searchFilterJson == null
        ? null
        : FilterData.fromJson(searchFilterJson.cast<String, dynamic>());
    if (searchFilter != null && searchFilter.isNotEmpty) {
      searchDelegate.filter = searchFilter;
    }
  }

  void restoreMode() {
    final mode = bucket!.read<String>(kRestoreModeKey);
    switch (InitialModePersistence.fromString(mode)) {
      case null:
      case InitialMode.view:
        // do nothing
        break;
      case InitialMode.edit:
        doEdit(requestFocus: true);
        break;
    }
  }
}
