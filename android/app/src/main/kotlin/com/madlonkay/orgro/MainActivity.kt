package com.madlonkay.orgro

import android.os.Bundle
import dev.fluttercommunity.workmanager.LoggingDebugHandler
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity(), CoroutineScope by MainScope() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.madlonkay.orgro/native_search").setMethodCallHandler {
            call, result ->
            launch {
                handleNativeSearchMethod(call, result, applicationContext)
            }
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (BuildConfig.DEBUG) {
            WorkmanagerDebug.setCurrent(LoggingDebugHandler())
        }
    }
}
