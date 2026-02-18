package com.journalx.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.journalx.app.R

class SmsReceiver : BroadcastReceiver() {
    
    companion object {
        const val CHANNEL_ID = "expense_detection"
        const val NOTIFICATION_ID = 1001
        const val ACTION_LOG_EXPENSE = "com.journalx.app.LOG_EXPENSE"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return
        
        val fullMessage = messages.joinToString(" ") { it.messageBody ?: "" }
        val sender = messages.firstOrNull()?.originatingAddress ?: return
        
        // Parse the expense from message
        val expenseData = parseExpenseMessage(fullMessage, sender)
        if (expenseData == null) return
        
        // Show notification
        showExpenseNotification(context, expenseData)
    }
    
    data class ExpenseData(
        val amount: Double,
        val receiver: String?,
        val source: String,
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
                       msg.contains("DEBIT")
        
        if (!isExpense) return null
        
        // Extract amount
        val amountPatterns = listOf(
            "RS\\.\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE),
            "₹\\s*([\\d,]+\\.?\\d*)".toRegex(),
            "INR\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE),
            "AMOUNT\\s*OF\\s*RS\\.\\s*([\\d,]+\\.?\\d*)".toRegex(RegexOption.IGNORE_CASE)
        )
        
        var amount: Double? = null
        for (pattern in amountPatterns) {
            val match = pattern.find(message)
            if (match != null) {
                val amountStr = match.groupValues[1].replace(",", "")
                amount = amountStr.toDoubleOrNull()
                break
            }
        }
        
        if (amount == null || amount <= 0) return null
        
        // Extract receiver/merchant
        val receiver = extractReceiver(message, sender)
        
        // Identify source bank
        val source = identifySource(sender, message)
        
        return ExpenseData(
            amount = amount,
            receiver = receiver,
            source = source,
            timestamp = System.currentTimeMillis()
        )
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
    
    private fun showExpenseNotification(context: Context, expenseData: ExpenseData) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android 8+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Expense Detection",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for detected expenses from SMS"
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Build the notification
        val amountStr = "₹${expenseData.amount.toInt()}"
        val receiverText = expenseData.receiver?.let { " at $it" } ?: ""
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentTitle("💰 Detected $amountStr expense")
            .setContentText("${expenseData.source}$receiverText")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Detected $amountStr expense${receiverText} from ${expenseData.source}\n\nTap to add description and save to your expenses."))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
