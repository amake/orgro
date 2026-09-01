package com.madlonkay.orgro

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.net.toUri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap

private const val TAG = "OrgroNativeSearch"

private val jobs = ConcurrentHashMap<String,Boolean>()

private const val jobTokenForId = "forId:"
private const val jobTokenForNamePrefix = "forNamePrefix:"
private const val jobTokenForExactName = "forExactName:"

suspend fun handleNativeSearchMethod(call: MethodCall, result: MethodChannel.Result, context: Context) = withContext(Dispatchers.Main) {
    try {
        when (call.method) {
            "findFileForId" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForId + requestId
                val orgId = call.argument<String>("orgId")
                if (orgId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'orgId'")
                    return@withContext
                }
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                jobs[requestId] = true
                result.success(findFileForId(requestId, orgId, dirIdentifier, context))
                jobs.remove(requestId)
            }
            "findFileWithNamePrefix" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForNamePrefix + requestId
                val namePrefix = call.argument<String>("namePrefix")
                if (namePrefix == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'namePrefix'")
                    return@withContext
                }
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                jobs[requestId] = true
                result.success(findFileWithNamePrefix(requestId, namePrefix, dirIdentifier, context))
                jobs.remove(requestId)
            }
            "findFileWithExactName" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForExactName + requestId
                val exactName = call.argument<String>("exactName")
                if (exactName == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'exactName'")
                    return@withContext
                }
                val dirIdentifier = call.argument<String>("dirIdentifier")
                if (dirIdentifier == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'dirIdentifier'")
                    return@withContext
                }
                jobs[requestId] = true
                result.success(findFileWithExactName(requestId, exactName, dirIdentifier, context))
                jobs.remove(requestId)
            }
            "cancelFindFileForId" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForId + requestId
                val removed = jobs.remove(requestId)
                Log.d(TAG, "Cancelling job $requestId; cancelled: ${removed ?: false}")
                result.success(removed ?: false)
            }
            "cancelFindFileWithNamePrefix" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForNamePrefix + requestId
                val removed = jobs.remove(requestId)
                Log.d(TAG, "Cancelling job $requestId; cancelled: ${removed ?: false}")
                result.success(removed ?: false)
            }
            "cancelFindFileWithExactName" -> {
                var requestId = call.argument<String>("requestId")
                if (requestId == null) {
                    result.error("MissingArg", "Required argument missing", "${call.method} requires 'requestId'")
                    return@withContext
                }
                requestId = jobTokenForExactName + requestId
                val removed = jobs.remove(requestId)
                Log.d(TAG, "Cancelling job $requestId; cancelled: ${removed ?: false}")
                result.success(removed ?: false)
            }
            else -> result.error("UnsupportedMethod", "${call.method} is not supported", null)
        }
    } catch (e: Exception) {
        result.error("ExecutionError", e.toString(), null)
    }
}

private suspend fun findFileForId(requestId: String, id: String, dirIdentifier: String, context: Context): Map<String, String>? {
    val parent = dirIdentifier.toUri()
    val found = iterateTree(requestId, parent, context) { uri, name ->
        name.endsWith(".org") && searchFileForId(uri, id, context)
    }
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

private suspend fun findFileWithNamePrefix(requestId: String, namePrefix: String, dirIdentifier: String, context: Context): Map<String, String>? {
    val parent = dirIdentifier.toUri()
    val found = iterateTree(requestId, parent, context) { _, name ->
        name.endsWith(".org") && name.startsWith(namePrefix)
    }
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

private suspend fun findFileWithExactName(requestId: String, exactName: String, dirIdentifier: String, context: Context): Map<String, String>? {
    val parent = dirIdentifier.toUri()
    val found = iterateTree(requestId, parent, context) { _, name -> name == exactName }
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
private suspend fun iterateTree(
    requestId: String,
    root: Uri,
    context: Context,
    predicate: suspend (Uri, String) -> Boolean
): Pair<Uri, String>? = withContext(Dispatchers.IO) {
    val parents = mutableListOf(root)
    while (parents.isNotEmpty()) {
        if (!jobs.containsKey(requestId)) {
            Log.d(TAG, "Quitting job $requestId due to cancellation")
            return@withContext null
        }
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
                if (!jobs.containsKey(requestId)) {
                    Log.d(TAG, "Quitting job $requestId due to cancellation")
                    return@withContext null
                }
                val documentId = it.getString(idColumn)
                val uri = DocumentsContract.buildDocumentUriUsingTree(parent, documentId)
                val mime = it.getString(mimeColumn)
                if (DocumentsContract.Document.MIME_TYPE_DIR == mime) {
                    parents.add(uri)
                    continue
                }
                val name = it.getString(nameColumn)
                Log.d(TAG,"Looking at $name")
                if (predicate(uri, name)) return@withContext Pair(uri, name)
            }
        }
    }
    null
}

private val idPattern = Regex("""^\s*:ID:\s*(?<value>\S+)\s*$""", RegexOption.IGNORE_CASE)

private suspend fun searchFileForId(uri: Uri, needle: String, context: Context): Boolean = withContext(Dispatchers.IO)  {
    context.contentResolver.openInputStream(uri)?.bufferedReader()?.useLines {
        for (line in it) {
            if (!line.contains(needle)) continue
            val m = idPattern.matchEntire(line) ?: continue
            if (m.groups[1]?.value == needle) return@withContext true
        }
    }
    false
}
