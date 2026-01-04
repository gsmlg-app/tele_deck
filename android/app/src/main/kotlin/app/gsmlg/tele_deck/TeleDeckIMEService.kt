package app.gsmlg.tele_deck

import android.content.Context
import android.hardware.display.DisplayManager
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * TeleDeck Input Method Service
 *
 * This IME service renders the keyboard on the secondary display (if available)
 * while returning a 0-height view on the primary screen to avoid blocking apps.
 */
class TeleDeckIMEService : InputMethodService() {

    companion object {
        private const val TAG = "TeleDeckIME"
        private const val ENGINE_ID = "tele_deck_ime_engine"
        private const val CHANNEL_NAME = "tele_deck/ime"
        private const val DISPLAY_DEBOUNCE_MS = 500L

        // Singleton reference for the broadcast receiver
        var instance: TeleDeckIMEService? = null
            private set
    }

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var presentation: VirtualKeyboardPresentation? = null
    private var displayManager: DisplayManager? = null
    private var secondaryDisplay: Display? = null
    private var primaryFlutterView: FlutterView? = null
    private var inputViewContainer: FrameLayout? = null

    // Handler for debouncing display events
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingDisplayAddedRunnable: Runnable? = null
    private var pendingDisplayRemovedRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "TeleDeckIMEService onCreate")

        // Initialize DisplayManager
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

        // Initialize or retrieve cached FlutterEngine
        initFlutterEngine()

        // Register display listener
        displayManager?.registerDisplayListener(displayListener, null)

        // Check for existing secondary display
        findSecondaryDisplay()
    }

    private fun initFlutterEngine() {
        // Check if engine is already cached
        flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)

        if (flutterEngine == null) {
            Log.d(TAG, "Creating new FlutterEngine with imeMain entrypoint")
            flutterEngine = FlutterEngine(this).apply {
                // Execute the custom imeMain Dart entrypoint
                val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(appBundlePath, "imeMain")
                )

                // Cache the engine for reuse
                FlutterEngineCache.getInstance().put(ENGINE_ID, this)
            }
        } else {
            Log.d(TAG, "Using cached FlutterEngine")
        }

        // Setup MethodChannel for receiving keyboard events from Flutter
        setupMethodChannel()
    }

    private fun setupMethodChannel() {
        flutterEngine?.let { engine ->
            methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "commitText" -> {
                        val text = call.argument<String>("text") ?: ""
                        commitText(text)
                        result.success(true)
                    }
                    "backspace" -> {
                        deleteBackward()
                        result.success(true)
                    }
                    "delete" -> {
                        deleteForward()
                        result.success(true)
                    }
                    "enter" -> {
                        sendEnter()
                        result.success(true)
                    }
                    "tab" -> {
                        sendTab()
                        result.success(true)
                    }
                    "moveCursor" -> {
                        val direction = call.argument<String>("direction") ?: ""
                        moveCursor(direction)
                        result.success(true)
                    }
                    "sendKeyEvent" -> {
                        val keyCode = call.argument<Int>("keyCode") ?: 0
                        val metaState = call.argument<Int>("metaState") ?: 0
                        sendKeyEventToApp(keyCode, metaState)
                        result.success(true)
                    }
                    "getConnectionStatus" -> {
                        result.success(currentInputConnection != null)
                    }
                    "isImeEnabled" -> {
                        result.success(isImeEnabled())
                    }
                    "isImeActive" -> {
                        result.success(isImeActive())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun deleteBackward() {
        currentInputConnection?.deleteSurroundingText(1, 0)
    }

    private fun deleteForward() {
        currentInputConnection?.deleteSurroundingText(0, 1)
    }

    private fun sendEnter() {
        currentInputConnection?.let { ic ->
            // Check if app expects action or newline
            val editorInfo = currentInputEditorInfo
            if (editorInfo != null && (editorInfo.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) == 0) {
                val action = editorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
                if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
                    ic.performEditorAction(action)
                    return
                }
            }
            // Default to newline
            ic.commitText("\n", 1)
        }
    }

    private fun sendTab() {
        currentInputConnection?.commitText("\t", 1)
    }

    private fun moveCursor(direction: String) {
        currentInputConnection?.let { ic ->
            when (direction) {
                "left" -> ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_DPAD_LEFT))
                "right" -> ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_DPAD_RIGHT))
                "up" -> ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_DPAD_UP))
                "down" -> ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_DPAD_DOWN))
            }
        }
    }

    private fun sendKeyEventToApp(keyCode: Int, metaState: Int) {
        currentInputConnection?.let { ic ->
            val downEvent = android.view.KeyEvent(
                System.currentTimeMillis(),
                System.currentTimeMillis(),
                android.view.KeyEvent.ACTION_DOWN,
                keyCode,
                0,
                metaState
            )
            val upEvent = android.view.KeyEvent(
                System.currentTimeMillis(),
                System.currentTimeMillis(),
                android.view.KeyEvent.ACTION_UP,
                keyCode,
                0,
                metaState
            )
            ic.sendKeyEvent(downEvent)
            ic.sendKeyEvent(upEvent)
        }
    }

    /**
     * Create a FlutterView for primary screen rendering (single-screen fallback mode).
     * The view is constrained to max 50% of screen height per spec.
     */
    private fun createPrimaryFlutterView(): View {
        Log.d(TAG, "Creating primary FlutterView for single-screen mode")

        val engine = flutterEngine ?: run {
            Log.e(TAG, "FlutterEngine not initialized")
            return createEmptyView()
        }

        // Create container with max 50% height
        val displayMetrics = resources.displayMetrics
        val maxHeight = (displayMetrics.heightPixels * 0.5).toInt()

        inputViewContainer = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                maxHeight
            )
        }

        // Create and attach FlutterView
        primaryFlutterView = FlutterView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Attach engine to FlutterView
        primaryFlutterView?.attachToFlutterEngine(engine)

        inputViewContainer?.addView(primaryFlutterView)

        // Notify Flutter about primary fallback mode
        notifyDisplayModeChanged("primary_fallback", null)

        return inputViewContainer!!
    }

    /**
     * Create an empty 0-height view (used when FlutterEngine is not ready)
     */
    private fun createEmptyView(): View {
        return FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0
            )
        }
    }

    private fun findSecondaryDisplay() {
        displayManager?.displays?.forEach { display ->
            if (display.displayId != Display.DEFAULT_DISPLAY) {
                Log.d(TAG, "Found secondary display: ${display.displayId} - ${display.name}")
                secondaryDisplay = display
                return
            }
        }
        Log.d(TAG, "No secondary display found")
        secondaryDisplay = null
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            Log.d(TAG, "Display added: $displayId - scheduling debounced handling")

            // Cancel any pending remove operation (prevent race condition)
            pendingDisplayRemovedRunnable?.let { mainHandler.removeCallbacks(it) }
            pendingDisplayRemovedRunnable = null

            // Cancel previous pending add
            pendingDisplayAddedRunnable?.let { mainHandler.removeCallbacks(it) }

            // Debounce display added event
            pendingDisplayAddedRunnable = Runnable {
                handleDisplayAdded(displayId)
            }
            mainHandler.postDelayed(pendingDisplayAddedRunnable!!, DISPLAY_DEBOUNCE_MS)
        }

        override fun onDisplayRemoved(displayId: Int) {
            Log.d(TAG, "Display removed: $displayId - scheduling debounced handling")

            // Cancel any pending add operation
            pendingDisplayAddedRunnable?.let { mainHandler.removeCallbacks(it) }
            pendingDisplayAddedRunnable = null

            // Cancel previous pending remove
            pendingDisplayRemovedRunnable?.let { mainHandler.removeCallbacks(it) }

            // Debounce display removed event
            pendingDisplayRemovedRunnable = Runnable {
                handleDisplayRemoved(displayId)
            }
            mainHandler.postDelayed(pendingDisplayRemovedRunnable!!, DISPLAY_DEBOUNCE_MS)
        }

        override fun onDisplayChanged(displayId: Int) {
            // Handle display changes if needed
        }
    }

    /**
     * Handle display added after debounce period
     */
    private fun handleDisplayAdded(displayId: Int) {
        Log.d(TAG, "Handling display added: $displayId")
        val display = displayManager?.getDisplay(displayId)
        if (display != null && displayId != Display.DEFAULT_DISPLAY) {
            secondaryDisplay = display

            // Clean up primary view if we were in fallback mode
            cleanupPrimaryFlutterView()

            // Show presentation on new display if input is active
            if (currentInputConnection != null && presentation == null) {
                showKeyboardPresentation()
            }

            // Request input view recreation to switch modes
            setInputView(createEmptyView())
        }
    }

    /**
     * Handle display removed after debounce period
     */
    private fun handleDisplayRemoved(displayId: Int) {
        Log.d(TAG, "Handling display removed: $displayId")

        // Null-safe check for secondary display
        val currentSecondaryId = secondaryDisplay?.displayId
        if (currentSecondaryId == displayId) {
            // Safely hide presentation
            hideKeyboardPresentation()
            secondaryDisplay = null

            // If input is still active, switch to primary fallback mode
            if (currentInputConnection != null) {
                Log.d(TAG, "Switching to primary fallback mode")
                setInputView(createPrimaryFlutterView())
            }
        }
    }

    override fun onCreateInputView(): View {
        Log.d(TAG, "onCreateInputView - hasSecondaryDisplay: ${secondaryDisplay != null}")

        return if (secondaryDisplay != null) {
            // Secondary display exists - return 0-height view for primary screen
            // The actual keyboard is shown on the secondary display via Presentation
            Log.d(TAG, "Using secondary display mode - returning 0-height view")
            createEmptyView()
        } else {
            // No secondary display - render keyboard on primary with 50% max height
            Log.d(TAG, "Using primary fallback mode - rendering on primary screen")
            createPrimaryFlutterView()
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        Log.d(TAG, "onStartInputView - restarting: $restarting")

        // Notify Flutter about input connection
        notifyFlutterConnectionStatus(true)

        // Show keyboard on secondary display if available
        showKeyboardPresentation()
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        Log.d(TAG, "onFinishInputView - finishing: $finishingInput")

        // Notify Flutter about disconnection
        notifyFlutterConnectionStatus(false)

        // Hide keyboard presentation (secondary display mode)
        hideKeyboardPresentation()

        // Clean up primary FlutterView if used (single-screen mode)
        cleanupPrimaryFlutterView()
    }

    /**
     * Clean up the primary FlutterView when switching modes or finishing input
     */
    private fun cleanupPrimaryFlutterView() {
        primaryFlutterView?.let { view ->
            Log.d(TAG, "Cleaning up primary FlutterView")
            try {
                view.detachFromFlutterEngine()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to detach FlutterView", e)
            }
        }
        primaryFlutterView = null
        inputViewContainer?.removeAllViews()
        inputViewContainer = null
    }

    private fun showKeyboardPresentation() {
        val display = secondaryDisplay
        if (display == null) {
            Log.d(TAG, "No secondary display available for presentation")
            return
        }

        if (presentation != null) {
            Log.d(TAG, "Presentation already showing")
            return
        }

        flutterEngine?.let { engine ->
            Log.d(TAG, "Showing keyboard presentation on display: ${display.displayId}")
            presentation = VirtualKeyboardPresentation(this, display, engine).apply {
                try {
                    show()
                    // Notify Flutter we're in secondary display mode
                    notifyDisplayModeChanged("secondary", display)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to show presentation", e)
                    // Log crash with display state
                    CrashLogger.logException(
                        context = this@TeleDeckIMEService,
                        exception = e as? Exception ?: Exception(e.message),
                        displayState = getDisplayState(),
                        engineState = "running"
                    )
                    presentation = null
                }
            }
        }
    }

    /**
     * Get current display state for crash logging
     */
    private fun getDisplayState(): Map<String, Any?> {
        val displayMetrics = resources.displayMetrics
        return CrashLogger.getDisplayStateMap(
            hasSecondaryDisplay = secondaryDisplay != null,
            secondaryDisplayId = secondaryDisplay?.displayId,
            primaryWidth = displayMetrics.widthPixels,
            primaryHeight = displayMetrics.heightPixels,
            secondaryWidth = secondaryDisplay?.mode?.physicalWidth,
            secondaryHeight = secondaryDisplay?.mode?.physicalHeight
        )
    }

    private fun hideKeyboardPresentation() {
        // Use local variable to prevent race conditions during rapid disconnect
        val currentPresentation = presentation
        presentation = null

        currentPresentation?.let {
            Log.d(TAG, "Hiding keyboard presentation")
            try {
                if (it.isShowing) {
                    it.dismiss()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to dismiss presentation", e)
            }
        }
    }

    private fun notifyFlutterConnectionStatus(connected: Boolean) {
        methodChannel?.invokeMethod("connectionStatus", mapOf("connected" to connected))
    }

    /**
     * Notify Flutter about display mode change
     */
    private fun notifyDisplayModeChanged(mode: String, display: Display?) {
        val width = display?.mode?.physicalWidth ?: resources.displayMetrics.widthPixels
        val height = display?.mode?.physicalHeight ?: resources.displayMetrics.heightPixels
        methodChannel?.invokeMethod("displayModeChanged", mapOf(
            "mode" to mode,
            "displayWidth" to width,
            "displayHeight" to height
        ))
    }

    /**
     * Check if TeleDeck is enabled in system keyboard settings
     */
    private fun isImeEnabled(): Boolean {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        return imm.enabledInputMethodList.any {
            it.packageName == packageName
        }
    }

    /**
     * Check if TeleDeck is the currently active keyboard
     */
    private fun isImeActive(): Boolean {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val currentIme = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.DEFAULT_INPUT_METHOD
        )
        return currentIme?.contains(packageName) == true
    }

    /**
     * Toggle keyboard visibility (for external triggers like physical buttons)
     */
    fun toggleKeyboard() {
        if (presentation != null) {
            hideKeyboardPresentation()
        } else {
            showKeyboardPresentation()
        }
    }

    /**
     * Show keyboard (for external triggers)
     */
    fun showKeyboard() {
        showKeyboardPresentation()
    }

    /**
     * Hide keyboard (for external triggers)
     */
    fun hideKeyboard() {
        hideKeyboardPresentation()
    }

    override fun onDestroy() {
        Log.d(TAG, "TeleDeckIMEService onDestroy")
        instance = null

        // Cancel any pending debounced operations
        pendingDisplayAddedRunnable?.let { mainHandler.removeCallbacks(it) }
        pendingDisplayRemovedRunnable?.let { mainHandler.removeCallbacks(it) }
        pendingDisplayAddedRunnable = null
        pendingDisplayRemovedRunnable = null

        // Clean up display listener
        displayManager?.unregisterDisplayListener(displayListener)

        // Clean up presentation (secondary display mode)
        hideKeyboardPresentation()

        // Clean up primary FlutterView (single-screen mode)
        cleanupPrimaryFlutterView()

        // Don't destroy the FlutterEngine - it's cached for reuse
        // FlutterEngineCache handles cleanup

        super.onDestroy()
    }
}
