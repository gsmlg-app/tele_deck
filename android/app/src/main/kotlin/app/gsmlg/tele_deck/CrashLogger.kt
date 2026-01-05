package app.gsmlg.tele_deck

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Crash logging utility for TeleDeck IME
 *
 * Logs crashes to files and shows system notifications with deep links to crash logs.
 */
object CrashLogger {
    private const val TAG = "TeleDeckCrashLogger"
    private const val CRASH_LOGS_DIR = "crash_logs"
    private const val CHANNEL_ID = "tele_deck_crash_channel"
    private const val NOTIFICATION_ID = 1001

    /**
     * Log a crash and optionally show a notification
     */
    fun logCrash(
        context: Context,
        errorType: String,
        message: String,
        stackTrace: String,
        displayState: Map<String, Any?>? = null,
        engineState: String = "running",
        showNotification: Boolean = true
    ): String? {
        try {
            val timestamp = System.currentTimeMillis()
            val id = "crash_$timestamp"

            val crashData = JSONObject().apply {
                put("id", id)
                put("timestamp", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date(timestamp)))
                put("errorType", errorType)
                put("message", message)
                put("stackTrace", stackTrace)
                put("engineState", engineState)

                displayState?.let { state ->
                    put("displayState", JSONObject().apply {
                        state.forEach { (key, value) ->
                            put(key, value)
                        }
                    })
                }
            }

            // Save to file
            val logsDir = File(context.filesDir, CRASH_LOGS_DIR)
            if (!logsDir.exists()) {
                logsDir.mkdirs()
            }

            val logFile = File(logsDir, "$id.log")
            logFile.writeText(crashData.toString())

            Log.d(TAG, "Crash logged: $id")

            // Show notification
            if (showNotification) {
                showCrashNotification(context, id, errorType)
            }

            // Cleanup old logs
            cleanupOldLogs(logsDir)

            return id
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log crash", e)
            return null
        }
    }

    /**
     * Log an exception
     */
    fun logException(
        context: Context,
        exception: Exception,
        displayState: Map<String, Any?>? = null,
        engineState: String = "running",
        showNotification: Boolean = true
    ): String? {
        return logCrash(
            context = context,
            errorType = exception.javaClass.simpleName,
            message = exception.message ?: "Unknown error",
            stackTrace = exception.stackTraceToString(),
            displayState = displayState,
            engineState = engineState,
            showNotification = showNotification
        )
    }

    /**
     * Show a notification about the crash
     */
    private fun showCrashNotification(context: Context, crashId: String, errorType: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create notification channel for Android O+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "TeleDeck Crash Reports",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications about TeleDeck keyboard crashes"
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Create intent to open crash logs
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "app.gsmlg.tele_deck.VIEW_CRASH_LOGS"
                putExtra("crash_id", crashId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("TeleDeck Keyboard Crashed")
                .setContentText("Error: $errorType. Tap to view details.")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show crash notification", e)
        }
    }

    /**
     * Get all crash logs
     */
    fun getCrashLogs(context: Context): List<JSONObject> {
        try {
            val logsDir = File(context.filesDir, CRASH_LOGS_DIR)
            if (!logsDir.exists()) {
                return emptyList()
            }

            return logsDir.listFiles { file -> file.extension == "log" }
                ?.mapNotNull { file ->
                    try {
                        JSONObject(file.readText())
                    } catch (e: Exception) {
                        null
                    }
                }
                ?.sortedByDescending { it.optString("timestamp") }
                ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get crash logs", e)
            return emptyList()
        }
    }

    /**
     * Get a specific crash log by ID
     */
    fun getCrashLogDetail(context: Context, id: String): JSONObject? {
        try {
            val logFile = File(context.filesDir, "$CRASH_LOGS_DIR/$id.log")
            if (!logFile.exists()) {
                return null
            }
            return JSONObject(logFile.readText())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get crash log detail", e)
            return null
        }
    }

    /**
     * Clear all crash logs
     */
    fun clearCrashLogs(context: Context): Boolean {
        try {
            val logsDir = File(context.filesDir, CRASH_LOGS_DIR)
            if (!logsDir.exists()) {
                return true
            }

            logsDir.listFiles { file -> file.extension == "log" }?.forEach { file ->
                file.delete()
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear crash logs", e)
            return false
        }
    }

    /**
     * Cleanup logs older than 7 days
     */
    private fun cleanupOldLogs(logsDir: File) {
        try {
            val sevenDaysAgo = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000)

            logsDir.listFiles { file -> file.extension == "log" }?.forEach { file ->
                if (file.lastModified() < sevenDaysAgo) {
                    file.delete()
                    Log.d(TAG, "Cleaned up old crash log: ${file.name}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cleanup old logs", e)
        }
    }

    /**
     * Get current display state as a map
     */
    fun getDisplayStateMap(
        hasSecondaryDisplay: Boolean,
        secondaryDisplayId: Int?,
        primaryWidth: Int,
        primaryHeight: Int,
        secondaryWidth: Int?,
        secondaryHeight: Int?
    ): Map<String, Any?> {
        return mapOf(
            "hasSecondaryDisplay" to hasSecondaryDisplay,
            "secondaryDisplayId" to secondaryDisplayId,
            "primaryWidth" to primaryWidth,
            "primaryHeight" to primaryHeight,
            "secondaryWidth" to secondaryWidth,
            "secondaryHeight" to secondaryHeight
        )
    }
}
