package com.tele.tele_presentation

import android.content.Context
import android.hardware.display.DisplayManager
import android.util.Log
import android.view.Display

/**
 * Helper class for detecting and managing external/secondary displays.
 *
 * Provides utilities to:
 * - Detect secondary displays
 * - Listen for display connection/disconnection events
 * - Get display information
 *
 * Usage:
 * ```kotlin
 * val displayHelper = DisplayHelper(context)
 *
 * // Check for secondary display
 * val secondaryDisplay = displayHelper.getSecondaryDisplay()
 *
 * // Listen for display changes
 * displayHelper.registerDisplayListener(object : DisplayHelper.DisplayListener {
 *     override fun onDisplayAdded(display: Display) {
 *         // Show presentation
 *     }
 *     override fun onDisplayRemoved(displayId: Int) {
 *         // Dismiss presentation
 *     }
 * })
 * ```
 */
class DisplayHelper(private val context: Context) {

    companion object {
        private const val TAG = "DisplayHelper"
        private const val DEBOUNCE_DELAY_MS = 500L
    }

    private val displayManager: DisplayManager =
        context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    private var displayCallback: DisplayManager.DisplayListener? = null
    private var listener: DisplayListener? = null
    private var pendingAddRunnable: Runnable? = null
    private var pendingRemoveRunnable: Runnable? = null
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    /**
     * Interface for display change callbacks.
     */
    interface DisplayListener {
        fun onDisplayAdded(display: Display)
        fun onDisplayRemoved(displayId: Int)
        fun onDisplayChanged(display: Display) {}
    }

    /**
     * Get the primary display.
     */
    fun getPrimaryDisplay(): Display? {
        return displayManager.getDisplay(Display.DEFAULT_DISPLAY)
    }

    /**
     * Get the first available secondary display.
     * Returns null if no secondary display is available.
     */
    fun getSecondaryDisplay(): Display? {
        val displays = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
        return displays.firstOrNull { it.displayId != Display.DEFAULT_DISPLAY && it.isValid }
    }

    /**
     * Get all available displays.
     */
    fun getAllDisplays(): List<Display> {
        return displayManager.displays.toList()
    }

    /**
     * Get all presentation-capable displays (excludes primary).
     */
    fun getPresentationDisplays(): List<Display> {
        return displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .filter { it.displayId != Display.DEFAULT_DISPLAY && it.isValid }
    }

    /**
     * Check if a secondary display is available.
     */
    fun hasSecondaryDisplay(): Boolean {
        return getSecondaryDisplay() != null
    }

    /**
     * Register a listener for display changes.
     * Events are debounced to handle rapid connect/disconnect.
     */
    fun registerDisplayListener(listener: DisplayListener) {
        this.listener = listener

        displayCallback = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) {
                Log.d(TAG, "Display added: $displayId")

                // Cancel any pending remove for this display
                pendingRemoveRunnable?.let { handler.removeCallbacks(it) }

                // Debounce the add event
                pendingAddRunnable?.let { handler.removeCallbacks(it) }
                pendingAddRunnable = Runnable {
                    val display = displayManager.getDisplay(displayId)
                    if (display != null && display.displayId != Display.DEFAULT_DISPLAY && display.isValid) {
                        listener.onDisplayAdded(display)
                    }
                }
                handler.postDelayed(pendingAddRunnable!!, DEBOUNCE_DELAY_MS)
            }

            override fun onDisplayRemoved(displayId: Int) {
                Log.d(TAG, "Display removed: $displayId")

                // Cancel any pending add
                pendingAddRunnable?.let { handler.removeCallbacks(it) }

                // Debounce the remove event
                pendingRemoveRunnable?.let { handler.removeCallbacks(it) }
                pendingRemoveRunnable = Runnable {
                    if (displayId != Display.DEFAULT_DISPLAY) {
                        listener.onDisplayRemoved(displayId)
                    }
                }
                handler.postDelayed(pendingRemoveRunnable!!, DEBOUNCE_DELAY_MS)
            }

            override fun onDisplayChanged(displayId: Int) {
                Log.d(TAG, "Display changed: $displayId")
                val display = displayManager.getDisplay(displayId)
                if (display != null && display.displayId != Display.DEFAULT_DISPLAY && display.isValid) {
                    listener.onDisplayChanged(display)
                }
            }
        }

        displayManager.registerDisplayListener(displayCallback, handler)
        Log.d(TAG, "Display listener registered")
    }

    /**
     * Unregister the display listener.
     */
    fun unregisterDisplayListener() {
        pendingAddRunnable?.let { handler.removeCallbacks(it) }
        pendingRemoveRunnable?.let { handler.removeCallbacks(it) }

        displayCallback?.let {
            displayManager.unregisterDisplayListener(it)
        }
        displayCallback = null
        listener = null
        Log.d(TAG, "Display listener unregistered")
    }

    /**
     * Get information about a specific display.
     */
    fun getDisplayInfo(displayId: Int): FlutterPresentation.DisplayInfo? {
        val display = displayManager.getDisplay(displayId) ?: return null
        return FlutterPresentation.DisplayInfo(
            displayId = display.displayId,
            name = display.name,
            width = display.width,
            height = display.height,
            rotation = display.rotation,
            isValid = display.isValid
        )
    }

    /**
     * Get information about all displays.
     */
    fun getAllDisplayInfo(): List<FlutterPresentation.DisplayInfo> {
        return getAllDisplays().map { display ->
            FlutterPresentation.DisplayInfo(
                displayId = display.displayId,
                name = display.name,
                width = display.width,
                height = display.height,
                rotation = display.rotation,
                isValid = display.isValid
            )
        }
    }
}
