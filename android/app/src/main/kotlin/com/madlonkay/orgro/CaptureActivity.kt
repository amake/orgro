package com.madlonkay.orgro

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity

class CaptureActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                when (intent.type) {
                    "text/plain" -> handleSendText(intent)
                    else -> {
                        Log.d("OrgroCapture", "Unhandleable intent type: ${intent.type}")
                    }
                }
            }
            else -> {
                Log.d("OrgroCapture", "Unhandleable intent action: ${intent?.action}")
            }
        }
        finish()
    }

    private fun handleSendText(intent: Intent) {
        var url: String? = null
        var title: String? = null
        var body: String? = null
        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
            Log.d("OrgroCapture", "Got text: $it")
            if (isUri(it)) {
                url = it
            } else {
                body = it
            }
        }
        title = intent.getStringExtra(Intent.EXTRA_TITLE)?.let {
            Log.d("OrgroCapture", "Got title: $it")
            it
        }
        title = title ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)?.let {
            Log.d("OrgroCapture", "Got subject: $it")
            it
        }
        shareParts(url, title, body)
    }

    private fun isUri(str: String): Boolean {
        return try {
            Uri.parse(str).scheme?.isNotBlank() == true
        } catch (e: IllegalArgumentException) {
            false
        }
    }

    private fun shareParts(url: String?, title: String?, body: String?) {
        val builder = Uri.Builder()
            .scheme(BuildConfig.ORG_PROTOCOL_SCHEME)
            .authority("capture")
        if (url != null) builder.appendQueryParameter("url", url)
        if (title != null) builder.appendQueryParameter("title", title)
        if (body != null) builder.appendQueryParameter("body", body)
        val intent = Intent(this, MainActivity::class.java).apply {
            data = builder.build()
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
    }
}
