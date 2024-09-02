package com.madlonkay.orgro

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val TAG = "OrgroNativeSearch"

suspend fun handleNativeSearchMethod(call: MethodCall, result: MethodChannel.Result, context: Context) = withContext(Dispatchers.Main) {
    try {
        when (call.method) {
            "findFileForId" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'id'")
                    return@withContext
                }
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                result.success(findFileForId(id, dirIdentifier, context))
            }
            else -> result.error("UnsupportedMethod", "${call.method} is not supported", null)
        }
    } catch (e: Exception) {
        result.error("ExecutionError", e.toString(), null)
    }
}

suspend fun findFileForId(id: String, dirIdentifier: String, context: Context): Map<String, String>? {
    val parent = Uri.parse(dirIdentifier)
    val found = iterateTree(parent, context) { searchFileForId(it, id, context) }
    if (found == null) return null
    val (uri, name) = found
    // Result compatible with file_picker_writable
    return mapOf(
        // Path not available in this context
        //"path" to found.absolutePath,
        "identifier" to uri.toString(),
        "persistable" to "true",
        "fileName" to name,
        "uri" to uri.toString()
    )
}

/**
 * Iterate over a file tree
 *
 * - Expects: Tree{+document} URI
 * - Returns: Tree+document URI and file name
 */
suspend fun iterateTree(
    root: Uri,
    context: Context,
    predicate: suspend (Uri) -> Boolean
): Pair<Uri, String>? = withContext(Dispatchers.IO) {
    val parents = mutableListOf(root)
    while (parents.isNotEmpty()) {
        val parent = parents.removeAt(0)
        val parentDocumentId = when {
            DocumentsContract.isDocumentUri(context, parent) -> DocumentsContract.getDocumentId(
                parent
            )
            else -> DocumentsContract.getTreeDocumentId(parent)
        }
        val childrenUri =
            DocumentsContract.buildChildDocumentsUriUsingTree(parent, parentDocumentId)
        context.contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
            ),
            null,
            null,
            null
        )?.use {
            val idColumn = it.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameColumn = it.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeColumn = it.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            while (it.moveToNext()) {
                val documentId = it.getString(idColumn)
                val uri = DocumentsContract.buildDocumentUriUsingTree(parent, documentId)
                val mime = it.getString(mimeColumn)
                if (DocumentsContract.Document.MIME_TYPE_DIR == mime) {
                    parents.add(uri)
                    continue
                }
                val name = it.getString(nameColumn)
                Log.d(TAG,"Looking at $name")
                if (!name.endsWith(".org")) continue
                if (predicate(uri)) return@withContext Pair(uri, name)
            }
        }
    }
    null
}

val idPattern = Regex("^\\s*:ID:\\s*(?<value>\\S+)\\s*\$", RegexOption.IGNORE_CASE)

suspend fun searchFileForId(uri: Uri, needle: String, context: Context): Boolean = withContext(Dispatchers.IO)  {
    context.contentResolver.openInputStream(uri)?.bufferedReader()?.useLines {
        for (line in it) {
            if (!line.contains(needle)) continue
            val m = idPattern.matchEntire(line) ?: continue
            if (m.groups["value"]?.value == needle) return@withContext true
        }
    }
    false
}