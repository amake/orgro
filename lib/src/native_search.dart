import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/data_source.dart';

const _channel = MethodChannel('com.madlonkay.orgro/native_search');

Future<NativeDataSource?> findFileForId({
  required String requestId,
  required String orgId,
  required String dirIdentifier,
}) async {
  final result = await _channel.invokeMapMethod<String, String>(
    'findFileForId',
    {
      'requestId': requestId,
      'orgId': orgId,
      'dirIdentifier': dirIdentifier,
    },
  );
  if (result == null) {
    return null;
  } else {
    // By convention we return a map compatible with FileInfo from
    // file_picker_writable
    final info = FileInfo.fromJson(result);
    return NativeDataSource(
      info.fileName ?? orgId,
      info.identifier,
      info.uri,
      persistable: info.persistable,
    );
  }
}

Future<bool> cancelFindFileForId({required String requestId}) async {
  final result = await _channel.invokeMethod<bool>(
    'cancelFindFileForId',
    {
      'requestId': requestId,
    },
  );
  return result ?? false;
}
