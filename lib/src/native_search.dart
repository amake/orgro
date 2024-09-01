import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/data_source.dart';

const _channel = MethodChannel('com.madlonkay.orgro/native_search');

Future<NativeDataSource?> findFileForId({
  required String id,
  required String dirIdentifier,
}) async {
  final result = await _channel.invokeMapMethod<String, String>(
    'findFileForId',
    {
      'id': id,
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
      info.fileName ?? id,
      info.identifier,
      info.uri,
      persistable: info.persistable,
    );
  }
}
