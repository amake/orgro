package com.madlonkay.orgro

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.InputStream
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {

    lateinit var channel: MethodChannel;

    private val loadQueue: Deque<Uri> = ArrayDeque()
    private val ready = AtomicBoolean(false)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.madlonkay.orgro/openFile")
        channel.setMethodCallHandler(this::handleMethod)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        when (intent?.action) {
            Intent.ACTION_VIEW -> {
                intent.data?.apply(if (ready.get()) this::loadUri else loadQueue::push)
            }
        }
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ready" -> {
                ready.set(true)
                while (loadQueue.isNotEmpty()) {
                    loadUri(loadQueue.pop())
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadUri(uri: Uri) {
        contentResolver.openInputStream(uri)?.readText()?.let {
            channel.invokeMethod("loadString", it, InvocationLogger("loadString"))
        }
    }
}

private class InvocationLogger(val method: String) : MethodChannel.Result {
    override fun notImplemented() {
        Log.e("Orgro", "$method not implemented")
    }

    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
        Log.e("Orgro", "$method error; code=$errorCode, message=$errorMessage, details=$errorDetails")
    }

    override fun success(result: Any?) {
        Log.d("Orgro", "$method success; result=$result")
    }
}

fun InputStream.readText(): String = bufferedReader().use { it.readText() }
