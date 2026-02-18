package com.journalx.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Telephony
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class SmsReceiver : BroadcastReceiver() {
    
    companion object {
        const val CHANNEL_ID = "expense_detection"
        const val NOTIFICATION_ID = 1001
        const val ACTION_LOG_EXPENSE = "com.journalx.app.LOG_EXPENSE"
        private const val TAG = "SmsReceiver"
        const val PREFS_NAME = "journalx_prefs"
        const val KEY_PENDING_AMOUNT = "pending_amount"
        const val KEY_PENDING_RECEIVER = "pending_receiver"
        const val KEY_PENDING_SOURCE = "pending_source"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return
        
        val fullMessage = messages.joinToString(" ") { it.messageBody ?: "" }
        val sender = messages.firstOrNull()?.originatingAddress ?: return
        
        Log.d(TAG, "SMS received from $sender: $fullMessage")
        
        // Parse the expense from message
        val expenseData = parseExpenseMessage(fullMessage, sender)
        if (expenseData == null) {
            Log.d(TAG, "Not an expense message or failed to parse")
            return
        }
        
        Log.d(TAG, "Detected expense: ${expenseData.amount} to ${expenseData.receiver}")
        
        // Auto-save expense to database
        saveExpenseToDatabase(context, expenseData)
        
        // Show simple notification
        showExpenseSavedNotification(context, expenseData)
    }
    
    data class ExpenseData(
        val amount: Double,
        val receiver: String?,
        val source: String,
        val cardLast4: String?,
        val timestamp: Long
    )
    
    private fun parseExpenseMessage(message: String, sender: String): ExpenseData? {
        val msg = message.uppercase()
        
        // Check if it's a debit/expense message (not credit)
        val isExpense = msg.contains("DEBITED") || 
                       msg.contains("PAID") || 
                       msg.contains("CHARGED") ||
                       msg.contains("PURCHASE") ||
                       msg.contains("SPENT") ||
                       msg.contains("TRANSACTION") ||
                       msg.contains("SENT") ||
                       msg.contains("DEBIT") ||
                       msg.contains("WITHDRAWN")
        
        if (!isExpense) return null
        
        // Extract amount - more comprehensive patterns
        val amountPatterns = listOf(
            "RS\\.\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE),
            "₹\\s*([\\d,]+\\.?\\d*)".toRegex(),
            "INR\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE),
            "AMOUNT\\s*(?:OF)?\\s*RS\\.\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE),
            "RUPEE\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE)
        )
        
        var amount: Double? = null
        for (pattern in amountPatterns) {
            val match = pattern.find(message)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                amount = amountStr.toDoubleOrNull()
                if (amount != null && amount > 0) break
            }
        }
        
        if (amount == null || amount <= 0) return null
        
        // Extract receiver/merchant
        val receiver = extractReceiver(message, sender)
        
        // Identify source bank
        val source = identifySource(sender, message)
        
        // Extract card last 4 digits
        val cardLast4 = extractCardLast4(message)
        
        return ExpenseData(
            amount = amount,
            receiver = receiver,
            source = source,
            cardLast4 = cardLast4,
            timestamp = System.currentTimeMillis()
        )
    }
    
    // Extract card last 4 digits from message
    private fun extractCardLast4(message: String): String? {
        val msg = message.uppercase()
        
        // Patterns to find card last 4 digits
        val cardPatterns = listOf(
            "CARD\\s*(?:ENDING\\s*)?(\\d{4})".toRegex(RegexOption.IGNORE_CASE),
            "ENDING\\s*(\\d{4})".toRegex(RegexOption.IGNORE_CASE),
            "\\*(\\d{4})\\b".toRegex(),
            "XX(\\d{4})".toRegex(RegexOption.IGNORE_CASE)
        )
        
        for (pattern in cardPatterns) {
            val match = pattern.find(msg)
            if (match != null) {
                return match.groupValues[1]
            }
        }
        
        return null
    }
    
    private fun extractReceiver(message: String, sender: String): String? {
        val msg = message.uppercase()
        
        // Patterns to find merchant/receiver - more comprehensive
        val patterns = listOf(
            "TO\\s+([A-Z][A-Z\\s]+)".toRegex(),           // TO PRASHANTH R
            "PAID\\s+TO\\s+([A-Z][A-Z0-9@]+)".toRegex(), // PAID TO merchant@upi
            "AT\\s+([A-Z][A-Z0-9\\s]+)".toRegex(),       // AT AMAZON
            "MERCHANT\\s+([A-Z]+)".toRegex(),
            "TO\\s+([A-Z0-9@]+)\\s+ON".toRegex(),
            "SENT\\s+TO\\s+([A-Z][A-Z\\s]+)".toRegex()   // SENT TO PRASHANTH
        )
        
        for (pattern in patterns) {
            val match = pattern.find(msg)
            if (match != null) {
                var value = match.groupValues[1].trim()
                // Clean up - remove trailing "ON" or other words
                value = value.replace("\\s+ON\\s+.*".toRegex(), "").trim()
                if (value.length >= 2 && value.length <= 30 && !value.matches(Regex("^[0-9]+$"))) {
                    return value
                }
            }
        }
        
        // For UPI transactions - extract VPA
        if (msg.contains("UPI") || msg.contains("@")) {
            val upiPattern = "([A-Za-z0-9._-]+@[A-Za-z0-9._-]+)".toRegex(RegexOption.IGNORE_CASE)
            val upiMatch = upiPattern.find(msg)
            if (upiMatch != null) {
                return upiMatch.groupValues[1]
            }
        }
        
        return null
    }
    
    private fun identifySource(sender: String, message: String): String {
        val senderUpper = sender.uppercase()
        val msgUpper = message.uppercase()
        
        return when {
            senderUpper.contains("HDFC") || msgUpper.contains("HDFC") -> "HDFC Bank"
            senderUpper.contains("SBI") || msgUpper.contains("STATE BANK") || msgUpper.contains("SBI") -> "SBI"
            senderUpper.contains("ICICI") || msgUpper.contains("ICICI") -> "ICICI Bank"
            senderUpper.contains("AXIS") || msgUpper.contains("AXIS") -> "Axis Bank"
            senderUpper.contains("KOTAK") || msgUpper.contains("KOTAK") -> "Kotak Bank"
            senderUpper.contains("YES") || msgUpper.contains("YES BANK") -> "Yes Bank"
            senderUpper.contains("INDUSIND") || msgUpper.contains("INDUSIND") -> "IndusInd Bank"
            senderUpper.contains("PNB") || msgUpper.contains("PUNJAB NATIONAL") -> "PNB"
            senderUpper.contains("CANARA") || msgUpper.contains("CANARA") -> "Canara Bank"
            senderUpper.contains("UNION") || msgUpper.contains("UNION BANK") -> "Union Bank"
            senderUpper.contains("BANK OF BARODA") || msgUpper.contains("BOB") -> "Bank of Baroda"
            senderUpper.contains("IDBI") || msgUpper.contains("IDBI") -> "IDBI Bank"
            senderUpper.contains("CITI") || msgUpper.contains("CITI") -> "Citibank"
            senderUpper.contains("STANDARD CHARTERED") || msgUpper.contains("SCB") -> "Standard Chartered"
            senderUpper.contains("AMEX") || msgUpper.contains("AMERICAN EXPRESS") -> "American Express"
            senderUpper.contains("PAYTM") || msgUpper.contains("PAYTM") -> "Paytm"
            senderUpper.contains("PHONEPE") || msgUpper.contains("PHONEPE") -> "PhonePe"
            senderUpper.contains("GPAY") || msgUpper.contains("GPAY") || msgUpper.contains("GOOGLE PAY") -> "Google Pay"
            senderUpper.contains("AMAZON") || msgUpper.contains("AMAZON") -> "Amazon Pay"
            else -> "Bank/Unknown"
        }
    }
    
    private fun saveExpenseToDatabase(context: Context, expenseData: ExpenseData) {
        try {
            val db = context.openOrCreateDatabase("journalx.db", Context.MODE_PRIVATE, null)
            
            // Create expenses table if not exists
            db.execSQL("""
                CREATE TABLE IF NOT EXISTS expenses (
                    id TEXT PRIMARY KEY,
                    amount REAL NOT NULL,
                    description TEXT NOT NULL,
                    category TEXT NOT NULL,
                    paymentModeId TEXT,
                    createdAt TEXT NOT NULL,
                    rawSms TEXT
                )
            """.trimIndent())
            
            // Create payment_modes table if not exists (for auto-adding new payment modes)
            db.execSQL("""
                CREATE TABLE IF NOT EXISTS payment_modes (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    lastFourDigits TEXT,
                    createdAt TEXT NOT NULL
                )
            """.trimIndent())
            
            // Generate combined payment mode ID and display name
            val bankName = expenseData.source
            val cardLast4 = expenseData.cardLast4
            
            // Build payment mode display: "HDFC Bank •••• 1234" or just "HDFC Bank" or just "•••• 1234"
            val paymentModeDisplay = when {
                bankName != "Bank/Unknown" && cardLast4 != null -> "$bankName •••• $cardLast4"
                bankName != "Bank/Unknown" -> bankName
                cardLast4 != null -> "•••• $cardLast4"
                else -> "Unknown"
            }
            
            // Check if this payment mode already exists, if not create it
            val checkQuery = "SELECT id FROM payment_modes WHERE name = ?"
            val cursor = db.rawQuery(checkQuery, arrayOf(paymentModeDisplay))
            val paymentModeId: String
            
            if (cursor.count == 0) {
                // Create new payment mode
                paymentModeId = java.util.UUID.randomUUID().toString()
                val createdAt = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.US).format(java.util.Date())
                
                // Determine type
                val type = when {
                    cardLast4 != null -> "Card"
                    bankName.contains("Bank", ignoreCase = true) -> "Bank"
                    bankName.contains("Paytm", ignoreCase = true) -> "UPI"
                    bankName.contains("PhonePe", ignoreCase = true) -> "UPI"
                    bankName.contains("Google Pay", ignoreCase = true) || bankName.contains("GPay", ignoreCase = true) -> "UPI"
                    else -> "Other"
                }
                
                val pmValues = android.content.ContentValues().apply {
                    put("id", paymentModeId)
                    put("name", paymentModeDisplay)
                    put("type", type)
                    put("lastFourDigits", cardLast4)
                    put("createdAt", createdAt)
                }
                db.insert("payment_modes", null, pmValues)
                Log.d(TAG, "Created new payment mode: $paymentModeDisplay")
            } else {
                cursor.moveToFirst()
                paymentModeId = cursor.getString(0)
            }
            cursor.close()
            
            // Generate UUID for expense
            val expenseId = java.util.UUID.randomUUID().toString()
            
            // Format timestamp as ISO 8601 string
            val timestamp = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.US).format(java.util.Date())
            
            // Insert expense
            val receiver = expenseData.receiver ?: "Unknown"
            
            val values = android.content.ContentValues().apply {
                put("id", expenseId)
                put("amount", expenseData.amount)
                put("description", "Sent to $receiver")
                put("category", "Transfer")
                put("paymentModeId", paymentModeId)
                put("createdAt", timestamp)
                put("rawSms", "Auto-detected from SMS")
            }
            
            db.insert("expenses", null, values)
            
            Log.d(TAG, "Expense saved: ₹${expenseData.amount} to $receiver with payment mode: $paymentModeDisplay")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error saving expense: ${e.message}")
        }
    }
    
    private fun showExpenseSavedNotification(context: Context, expenseData: ExpenseData) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android 8+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Expense Detection",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for detected expenses from SMS"
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Create intent to open the app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build the notification
        val amountStr = "₹${expenseData.amount.toInt()}"
        val receiverText = expenseData.receiver?.let { " to $it" } ?: ""
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_save)
            .setContentTitle("✅ Expense Saved!")
            .setContentText("$amountStr$receiverText from ${expenseData.source}")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("$amountStr$receiverText from ${expenseData.source}\n\nAuto-saved to your expenses."))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
