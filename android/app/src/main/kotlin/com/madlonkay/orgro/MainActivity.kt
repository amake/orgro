package com.madlonkay.orgro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.madlonkay.orgro/native_search").setMethodCallHandler {
            call, result ->
            // TODO(aaron): Implement for Android
            result.error("NotImplemented", "$call not implemented", null)
        }
    }
}
