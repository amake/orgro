import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/timestamps.dart';

extension TimestampsExtension on DocumentPageState {
  void onTimestampTap(OrgNode timestamp) async {
    switch (timestamp) {
      // OrgDateRangeTimestamp is rendered as two OrgSimpleTimestamps so that is
      // covered by this case
      case OrgSimpleTimestamp():
        await _handleSimpleTimestamp(timestamp);
        break;
      case OrgTimeRangeTimestamp():
        await _handleRangeTimestamp(timestamp);
        break;
      // OrgDiaryTimestamp can't be meaningfully handled, so we ignore it
    }
  }

  Future<void> _handleSimpleTimestamp(OrgSimpleTimestamp timestamp) async {
    final context = this.context;
    var newTimestamp = timestamp;
    final dateResult = await showDatePicker(
      context: context,
      firstDate: kDatePickerFirstDate,
      lastDate: kDatePickerLastDate,
      currentDate: timestamp.date.toDateTime(),
    );
    if (dateResult != null) {
      newTimestamp = timestamp.copyWith(date: dateResult.toOrgDate());
    }
    if (!context.mounted) return;
    if (timestamp.time case OrgTime time) {
      final timeResult = await showTimePicker(
        context: context,
        initialTime: time.toTimeOfDay(),
      );
      if (timeResult != null) {
        newTimestamp = newTimestamp.copyWith(time: timeResult.toOrgTime());
      }
    }
    _updateNode(timestamp, newTimestamp);
  }

  Future<void> _handleRangeTimestamp(OrgTimeRangeTimestamp timestamp) async {
    final context = this.context;
    var newTimestamp = timestamp;
    final dateResult = await showDatePicker(
      context: context,
      firstDate: kDatePickerFirstDate,
      lastDate: kDatePickerLastDate,
      currentDate: timestamp.date.toDateTime(),
    );
    if (dateResult != null) {
      newTimestamp = timestamp.copyWith(date: dateResult.toOrgDate());
    }
    if (!context.mounted) return;
    final startResult = await showTimePicker(
      context: context,
      initialTime: timestamp.timeStart.toTimeOfDay(),
      helpText:
          AppLocalizations.of(context)!.startTimePickerTitle.toUpperCase(),
    );
    if (startResult != null) {
      newTimestamp = newTimestamp.copyWith(timeStart: startResult.toOrgTime());
    }
    if (!context.mounted) return;
    final endResult = await showTimePicker(
      context: context,
      initialTime: timestamp.timeEnd.toTimeOfDay(),
      helpText: AppLocalizations.of(context)!.endTimePickerTitle.toUpperCase(),
    );
    if (endResult != null) {
      newTimestamp = newTimestamp.copyWith(timeEnd: endResult.toOrgTime());
    }
    _updateNode(timestamp, newTimestamp);
  }

  void _updateNode(OrgNode oldNode, OrgNode newNode) {
    if (oldNode == newNode) return;
    final newDoc =
        DocumentProvider.of(
              context,
            ).doc.editNode(oldNode)!.replace(newNode).commit()
            as OrgTree;
    updateDocument(newDoc);
  }
}
