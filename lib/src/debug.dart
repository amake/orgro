import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/error.dart';

// Set to true to make debug builds look like release builds. Useful for taking
// App Store screenshots on the iOS Simulator.
const kScreenshotMode = false;

Future<T> time<T>(String tag, FutureOr<T> Function() func) async {
  final start = DateTime.now();
  final ret = await func();
  final end = DateTime.now();
  debugPrint('$tag: ${end.difference(start).inMilliseconds} ms');
  return ret;
}

Object? logError(Object? e, StackTrace s) {
  debugPrint(e.toString());
  debugPrintStack(stackTrace: s);
  return e;
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
  BuildContext context,
  Object? msgObject,
) {
  String message;
  if (msgObject is PlatformException) {
    message = msgObject.message ?? msgObject.code;
  } else if (msgObject is OrgroError) {
    message = msgObject.localizedMessage(context);
  } else {
    message = msgObject.toString();
  }
  return ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
