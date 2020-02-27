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
import kotlinx.coroutines.*
import java.io.InputStream
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity(), CoroutineScope by MainScope() {

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
                intent.data?.let { uri ->
                    if (ready.get()) {
                        launch { loadUri(uri) }
                    } else {
                        synchronized(loadQueue) {
                            loadQueue.push(uri)
                        }
                    }
                }
            }
        }
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ready" -> {
                ready.set(true)
                synchronized(loadQueue) {
                    while (loadQueue.isNotEmpty()) {
                        val queued = loadQueue.pop()
                        launch { loadUri(queued) }
                    }
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private suspend fun loadUri(uri: Uri) = withContext(Dispatchers.IO) {
        val start = System.currentTimeMillis()
        contentResolver.openInputStream(uri)?.readText()?.let {
            val end = System.currentTimeMillis()
            Log.d("Orgro", "loading URI complete (${end - start} ms)")
            withContext(Dispatchers.Main) {
                channel.invokeMethod("loadString", it, InvocationLogger("loadString"))
            }
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
