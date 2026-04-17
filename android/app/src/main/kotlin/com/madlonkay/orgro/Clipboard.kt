package com.madlonkay.orgro

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import androidx.core.net.toUri
import codeux.design.filepicker.file_picker_writable.getChildByDisplayName
import codeux.design.filepicker.file_picker_writable.getParent

private const val TAG = "OrgroClipboard"

suspend fun handleClipboardMethod(call: MethodCall, result: MethodChannel.Result, context: Context) = withContext(Dispatchers.Main) {
    try {
        when (call.method) {
            "hasClipboardImageData" -> {
                result.success(hasClipboardImageData(context))
            }
            "saveClipboardImages" -> {
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                val relativePath = call.argument<String?>("relativePath")
                if (!call.hasArgument("relativePath")) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'relativePath'")
                    return@withContext
                }
                val filenamePrefix = call.argument<String>("filenamePrefix")
                if (filenamePrefix == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'filenamePrefix'")
                    return@withContext
                }
                result.success(saveClipboardImages(dirIdentifier, relativePath, filenamePrefix, context))
            }
            "saveKeyboardImage" -> {
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                val relativePath = call.argument<String?>("relativePath")
                if (!call.hasArgument("relativePath")) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'relativePath'")
                    return@withContext
                }
                val filenamePrefix = call.argument<String>("filenamePrefix")
                if (filenamePrefix == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'filenamePrefix'")
                    return@withContext
                }
                val mimeType = call.argument<String>("mimeType")
                if (mimeType == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'mimeType'")
                    return@withContext
                }
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'uri'")
                    return@withContext
                }
                val data = call.argument<ByteArray?>("data")
                if (!call.hasArgument("data")) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'data'")
                    return@withContext
                }
                result.success(saveKeyboardImage(dirIdentifier, relativePath, filenamePrefix, mimeType, uri, data, context))
            }
            else -> result.error("UnsupportedMethod", "${call.method} is not supported", null)
        }
    } catch (e: Exception) {
        e.printStackTrace()
        result.error("ExecutionError", e.toString(), null)
    }
}

private fun hasClipboardImageData(context: Context): Boolean {
    val clipboard = context.getSystemService(ClipboardManager::class.java)
    if (!clipboard.hasPrimaryClip()) return false

    val data = clipboard.primaryClip ?: return false
    val description = data.description
    if (description.hasMimeType(ClipDescription.MIMETYPE_TEXT_URILIST)) {
        for (i in 0 until data.itemCount) {
            val uri = data.getItemAt(i).uri
            val mimeType = context.contentResolver.getType(uri) ?: continue
            if (mimeType.startsWith("image/")) return true
        }
    }

    for (i in 0 until description.mimeTypeCount) {
        val mimeType = description.getMimeType(i)
        if (mimeType.startsWith("image/")) return true
    }

    return false
}

private suspend fun saveClipboardImages(
    dirIdentifier: String,
    relativePath: String?,
    filenamePrefix: String,
    context: Context
): List<String> = withContext(Dispatchers.IO) {
    val results = mutableListOf<String>()

    val parent = dirIdentifier.toUri().let {
        if (relativePath == null) it
        else mkdirp(it, relativePath, context)
    }

    val clipboard = context.getSystemService(ClipboardManager::class.java)
    if (!clipboard.hasPrimaryClip()) return@withContext results

    val mimeTypeMap = MimeTypeMap.getSingleton()

    val data = clipboard.primaryClip ?: return@withContext results

    for ((i, item) in data.items().withIndex()) {
        val uri = item.uri
        val uriType = context.contentResolver.getType(uri)

        item@ for (mimeType in data.description.mimeTypes().plus(uriType)) {
            if (mimeType?.startsWith("image/") != true) continue

            context.contentResolver.openInputStream(uri)?.use { imageStream ->
                val ext = mimeTypeMap.getExtensionFromMimeType(mimeType) ?: "dat"
                val fileName = "${filenamePrefix}_$i.$ext"
                val imageFile = DocumentsContract.createDocument(
                    context.contentResolver,
                    parent,
                    mimeType,
                    fileName
                ) ?: continue@item
                Log.d(TAG, "Saving item $i to $imageFile")
                context.contentResolver.openOutputStream(imageFile)?.use { fileStream ->
                    imageStream.copyTo(fileStream)
                    results.add(fileName)
                    break@item
                }
            }
        }
    }
    return@withContext results
}

// Largely copied from file_picker_writable and reusing some functions from same
private suspend fun mkdirp(start: Uri, relativePath: String, context: Context): Uri = withContext(Dispatchers.IO) {
    val stack = mutableListOf(start)
    for (segment in relativePath.split('/', '\\')) {
        when (segment) {
            "" -> {
            }
            "." -> {
            }
            ".." -> {
                val last = stack.removeAt(stack.lastIndex)
                if (stack.isEmpty()) {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        throw Exception("Cannot resolve 'up' the filesystem before Android 8")
                    }
                    val parent = getParent(last, context)
                        ?: throw Exception("Could not resolve parent")
                    stack.add(parent)
                }
            }
            else -> {
                val next = getChildByDisplayName(stack.last(), segment, context)
                    ?: DocumentsContract.createDocument(
                        context.contentResolver,
                        stack.last(),
                        DocumentsContract.Document.MIME_TYPE_DIR,
                        segment
                    ) ?: throw Exception("Failed to create dir $segment")
                stack.add(next)
            }
        }
    }
    stack.last()
}

private fun ClipData.items() = sequence {
    for (i in 0 until itemCount) yield(getItemAt(i))
}

private fun ClipDescription.mimeTypes() = sequence {
    for (i in 0 until mimeTypeCount) yield(getMimeType(i))
}

private suspend fun saveKeyboardImage(
    dirIdentifier: String,
    relativePath: String?,
    filenamePrefix: String,
    mimeType: String,
    uri: String,
    data: ByteArray?,
    context: Context
): String? = withContext(Dispatchers.IO) {
    val parent = dirIdentifier.toUri().let {
        if (relativePath == null) it
        else mkdirp(it, relativePath, context)
    }
    val mimeTypeMap = MimeTypeMap.getSingleton()

    val uri = uri.toUri()
    val uriType = context.contentResolver.getType(uri)

    val fileName = try {
        // Experimentally, with Gboard on an API 36 (Android 16) emulator, this
        // never succeeds
        getDisplayName(uri, context.contentResolver)
    } catch (e: Exception) {
        Log.d(TAG, "Failed to get display name for URI $uri: $e")
        null
    }

    for (mimeType in arrayOf(mimeType, uriType)) {
        if (mimeType?.startsWith("image/") != true) continue

        val ext = mimeTypeMap.getExtensionFromMimeType(mimeType) ?: "dat"
        val fileName = fileName
            // Experimentally, with Gboard on an API 36 (Android 16) emulator,
            // the last path segment does appear to be a "normal" file name, and
            // we end up accepting it here. Further, the file name appears to be
            // randomized, so we can't deduplicate against an existing file if
            // e.g. the user inserts the same sticker/GIF multiple times.
            ?: uri.pathSegments.lastOrNull()?.let { if (it.endsWith(".$ext")) it else null }
            ?: "$filenamePrefix.$ext"
        val imageFile = DocumentsContract.createDocument(
            context.contentResolver,
            parent,
            mimeType,
            fileName
        ) ?: continue

        Log.d(TAG, "Saving keyboard item $uri to $imageFile")

        if (data != null) {
            context.contentResolver.openOutputStream(imageFile)?.use { fileStream ->
                fileStream.write(data)
                return@withContext fileName
            }
        } else {
            context.contentResolver.openInputStream(uri)?.use { imageStream ->
                context.contentResolver.openOutputStream(imageFile)?.use { fileStream ->
                    imageStream.copyTo(fileStream)
                    return@withContext fileName
                }
            }
        }
    }

    return@withContext null
}

private suspend fun getDisplayName(
    uri: Uri,
    contentResolver: ContentResolver
): String? = withContext(Dispatchers.IO) {
    // The query, because it only applies to a single document, returns only one
    // row. There's no need to filter, sort, or select fields, because we want
    // all fields for one document.
    val cursor: Cursor? = contentResolver.query(
        uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null, null
    )

    cursor?.use {
        if (!it.moveToFirst()) {
            throw Exception("Cursor returned empty while trying to read file info for $uri")
        }

        // Note it's called "Display Name". This is provider-specific, and might
        // not necessarily be the file name.
        val nameIdx = it.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME)
        it.getString(nameIdx)
    }
}
