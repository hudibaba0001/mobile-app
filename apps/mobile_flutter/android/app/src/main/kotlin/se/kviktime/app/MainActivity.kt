package se.kviktime.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_EXPORT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> saveToDownloads(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        val bytes = call.argument<ByteArray>("bytes")

        if (fileName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
            result.error("INVALID_ARGS", "Missing fileName or file bytes", null)
            return
        }

        try {
            val location = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveToPublicDownloads(fileName, mimeType, bytes)
            } else {
                // Legacy fallback for old Android versions.
                saveToAppExternalDownloads(fileName, bytes)
            }
            result.success(location)
        } catch (e: SecurityException) {
            result.error(
                "SECURITY",
                e.message ?: "Permission denied while saving to Downloads",
                null
            )
        } catch (e: Exception) {
            result.error(
                "EXPORT_FAILED",
                e.message ?: "Failed to save file to Downloads",
                null
            )
        }
    }

    private fun saveToPublicDownloads(
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        val resolver = contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/KvikTime")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            ?: throw IllegalStateException("Unable to create Downloads entry")

        resolver.openOutputStream(uri)?.use { stream ->
            stream.write(bytes)
            stream.flush()
        } ?: throw IllegalStateException("Unable to open Downloads output stream")

        contentValues.clear()
        contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, contentValues, null, null)

        return uri.toString()
    }

    private fun saveToAppExternalDownloads(fileName: String, bytes: ByteArray): String {
        val downloadsDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw IllegalStateException("Downloads directory unavailable")

        val kvikTimeDir = File(downloadsDir, "KvikTime")
        if (!kvikTimeDir.exists()) {
            kvikTimeDir.mkdirs()
        }

        val outFile = File(kvikTimeDir, fileName)
        FileOutputStream(outFile).use { stream ->
            stream.write(bytes)
            stream.flush()
        }

        return outFile.absolutePath
    }

    companion object {
        private const val FILE_EXPORT_CHANNEL = "se.kviktime.app/file_export"
    }
}
