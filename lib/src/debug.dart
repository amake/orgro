import 'dart:async';

import 'package:flutter/foundation.dart';

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

Future logError(Object e, StackTrace s) async {
  debugPrint(e.toString());
  debugPrint(s.toString());
  return e;
}
