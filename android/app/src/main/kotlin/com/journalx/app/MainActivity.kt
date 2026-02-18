package com.journalx.app

import android.Manifest
import android.content.ContentResolver
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "android/PERMISSIONS"
    private val SMS_CHANNEL = "android/SMS"
    private val EXPORT_CHANNEL = "android/EXPORT"
    private val INTENT_CHANNEL = "android/INTENT"
    private val NOTIFICATION_PERMISSION_CODE = 100
    private val SMS_PERMISSION_CODE = 101
    
    // Store pending expense data
    companion object {
        var pendingExpenseData: Map<String, Any>? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Permission channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    requestNotificationPermission(result)
                }
                "requestSmsPermission" -> {
                    requestSmsPermission(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // SMS operations channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readOldSms" -> {
                    val days = call.argument<Int>("days") ?: 7
                    readOldSms(days, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Export operations channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXPORT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val filename = call.argument<String>("filename") ?: "export.csv"
                    val content = call.argument<String>("content") ?: ""
                    saveToDownloads(filename, content, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Intent channel for pending expense data
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingIntent" -> {
                    val data = pendingExpenseData
                    pendingExpenseData = null  // Clear after reading
                    result.success(data)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }
        result.success(true)
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) 
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
                SMS_PERMISSION_CODE
            )
        }
        result.success(true)
    }

    private fun readOldSms(days: Int, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) 
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
            return
        }

        try {
            val smsList = mutableListOf<Map<String, Any>>()
            val uri: Uri = Uri.parse("content://sms/inbox")
            val projection = arrayOf("_id", "address", "body", "date", "type")
            
            // Calculate date N days ago
            val cutoffTime = System.currentTimeMillis() - (days * 24 * 60 * 60 * 1000L)
            
            val selection = "date >= ?"
            val selectionArgs = arrayOf(cutoffTime.toString())
            val sortOrder = "date DESC"

            val cursor: Cursor? = contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")
                
                while (it.moveToNext()) {
                    val address = it.getString(addressIndex) ?: continue
                    val body = it.getString(bodyIndex) ?: continue
                    val date = it.getLong(dateIndex)
                    
                    smsList.add(mapOf(
                        "address" to address,
                        "body" to body,
                        "date" to date
                    ))
                }
            }

            result.success(smsList)
        } catch (e: Exception) {
            result.error("READ_ERROR", e.message, null)
        }
    }

    private fun saveToDownloads(filename: String, content: String, result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Use MediaStore for Android 10+
                val contentValues = android.content.ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, filename)
                    put(MediaStore.Downloads.MIME_TYPE, "text/csv")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                
                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                uri?.let {
                    contentResolver.openOutputStream(it)?.use { outputStream ->
                        outputStream.write(content.toByteArray())
                    }
                    
                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(it, contentValues, null, null)
                }
            } else {
                // For older versions, use direct file access
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                val file = File(downloadsDir, filename)
                FileOutputStream(file).use { outputStream ->
                    outputStream.write(content.toByteArray())
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("EXPORT_ERROR", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
