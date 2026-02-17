package com.journalx.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel

class PaymentDetectionService : AccessibilityService() {

    companion object {
        // Package names for payment apps - including variants
        val PAYMENT_APP_PACKAGES = listOf(
            // Google Pay
            "com.google.android.apps.nbu.paisa.user",
            "com.google.android.apps.nbu.paisa.user.global",
            "com.google.android.apps.nbu.paisa",
            // PhonePe
            "com.phonepe.app",
            "com.phonepe.app.beta",
            // Paytm
            "com.paytm.nativMID",
            "com.paytm.nativMID.mgid",
            "com.paytm.shopping"
        )
        
        const val CHANNEL_ID = "payment_detection"
        const val NOTIFICATION_ID = 1001
        private const val TAG = "PaymentDetection"
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "PaymentDetectionService connected")
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Payment App Detection",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when payment apps are opened"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Check if the event is a window state change
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            
            if (packageName != null) {
                Log.d(TAG, "Package changed to: $packageName")
                
                // Check if the foreground app is a payment app
                if (PAYMENT_APP_PACKAGES.any { packageName.startsWith(it) }) {
                    Log.d(TAG, "Detected payment app: $packageName")
                    showNotification(packageName)
                }
            }
        }
    }

    private fun showNotification(packageName: String) {
        val appName = when {
            packageName.contains("google.android.apps.nbu.paisa") -> "Google Pay"
            packageName.contains("phonepe") -> "PhonePe"
            packageName.contains("paytm") -> "Paytm"
            else -> "Payment App"
        }

        Log.d(TAG, "Showing notification for: $appName")

        // Check notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            if (!notificationManager.areNotificationsEnabled()) {
                Log.w(TAG, "Notifications are not enabled")
                return
            }
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("💰 Just paid via $appName?")
            .setContentText("Tap here to log your expense!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 250, 250, 250))
        
        if (launchIntent != null) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setContentIntent(pendingIntent)
        }

        val notification = builder.build()

        try {
            NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "Notification sent successfully")
        } catch (e: SecurityException) {
            Log.e(TAG, "Notification permission not granted: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification: ${e.message}")
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }
}
