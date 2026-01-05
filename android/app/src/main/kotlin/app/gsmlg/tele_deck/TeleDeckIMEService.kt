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
import android.view.WindowManager
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
    private var isInPrimaryFallbackMode: Boolean = false
    private var isPrimaryViewAttached: Boolean = false
    private var isDartEntrypointExecuted: Boolean = false

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
            Log.d(TAG, "Creating new FlutterEngine (Dart entrypoint will be executed when view is ready)")
            flutterEngine = FlutterEngine(this).apply {
                // Cache the engine for reuse
                FlutterEngineCache.getInstance().put(ENGINE_ID, this)
            }
            isDartEntrypointExecuted = false
        } else {
            Log.d(TAG, "Using cached FlutterEngine")
            isDartEntrypointExecuted = true
        }

        // Setup MethodChannel for receiving keyboard events from Flutter
        setupMethodChannel()
    }

    private fun executeDartEntrypointIfNeeded() {
        if (isDartEntrypointExecuted) {
            Log.d(TAG, "Dart entrypoint already executed")
            return
        }

        val engine = flutterEngine ?: return

        Log.d(TAG, "Executing Dart entrypoint: imeMain")
        val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(appBundlePath, "imeMain")
        )
        isDartEntrypointExecuted = true
    }

    /**
     * Set up MethodChannel on a FlutterEngine.
     * This is called for both the primary engine and the Presentation's local engine.
     */
    private fun setupMethodChannelOnEngine(engine: FlutterEngine) {
        Log.d(TAG, "Setting up MethodChannel on engine: ${engine.hashCode()}")
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
                Log.d(TAG, "MethodChannel received: ${call.method}")
                when (call.method) {
                    "commitText" -> {
                        // Flutter sends text directly as arguments, not as a map
                        val text = call.arguments as? String ?: ""
                        Log.d(TAG, "MethodChannel commitText: '$text'")
                        commitText(text)
                        result.success(true)
                    }
                    "backspace" -> {
                        Log.d(TAG, "MethodChannel backspace")
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
                        // Flutter sends offset as int directly
                        val offset = call.arguments as? Int ?: 0
                        Log.d(TAG, "MethodChannel moveCursor: $offset")
                        moveCursorByOffset(offset)
                        result.success(true)
                    }
                    "sendKeyEvent" -> {
                        // Flutter sends a map with keyCode and modifier booleans
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        val keyCode = (args["keyCode"] as? Int) ?: 0
                        val shift = (args["shift"] as? Boolean) ?: false
                        val ctrl = (args["ctrl"] as? Boolean) ?: false
                        val alt = (args["alt"] as? Boolean) ?: false
                        val meta = (args["meta"] as? Boolean) ?: false

                        // Build metaState from modifier flags
                        var metaState = 0
                        if (shift) metaState = metaState or android.view.KeyEvent.META_SHIFT_ON
                        if (ctrl) metaState = metaState or android.view.KeyEvent.META_CTRL_ON
                        if (alt) metaState = metaState or android.view.KeyEvent.META_ALT_ON
                        if (meta) metaState = metaState or android.view.KeyEvent.META_META_ON

                        Log.d(TAG, "MethodChannel sendKeyEvent: keyCode=$keyCode, metaState=$metaState")
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
        // Keep reference to the channel for sending notifications back to Flutter
        methodChannel = channel
    }

    private fun setupMethodChannel() {
        flutterEngine?.let { engine ->
            setupMethodChannelOnEngine(engine)
        }
    }

    private fun commitText(text: String) {
        Log.d(TAG, "commitText: '$text', hasConnection: ${currentInputConnection != null}")
        currentInputConnection?.commitText(text, 1)
    }

    private fun deleteBackward() {
        Log.d(TAG, "deleteBackward, hasConnection: ${currentInputConnection != null}")
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

    private fun moveCursorByOffset(offset: Int) {
        currentInputConnection?.let { ic ->
            // Get current cursor position and move by offset
            val extracted = ic.getExtractedText(android.view.inputmethod.ExtractedTextRequest(), 0)
            if (extracted != null) {
                val newPos = (extracted.selectionStart + offset).coerceIn(0, extracted.text?.length ?: 0)
                ic.setSelection(newPos, newPos)
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
        isPrimaryViewAttached = true
        isInPrimaryFallbackMode = true

        inputViewContainer?.addView(primaryFlutterView)

        // Execute Dart entrypoint now that view is ready
        executeDartEntrypointIfNeeded()

        // Notify Flutter lifecycle that app is resumed
        engine.lifecycleChannel.appIsResumed()

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
        val displays = displayManager?.displays
        Log.d(TAG, "Searching for secondary display. Total displays: ${displays?.size ?: 0}")

        displays?.forEach { display ->
            Log.d(TAG, "Display ${display.displayId}: ${display.name}, state: ${display.state}, flags: ${display.flags}")
            if (display.displayId != Display.DEFAULT_DISPLAY) {
                Log.d(TAG, "Found secondary display: ${display.displayId} - ${display.name}")
                Log.d(TAG, "  Size: ${display.mode.physicalWidth}x${display.mode.physicalHeight}")
                Log.d(TAG, "  State: ${display.state}, Flags: ${display.flags}")
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
        Log.d(TAG, "======= onCreateInputView START =======")
        Log.d(TAG, "onCreateInputView - hasSecondaryDisplay: ${secondaryDisplay != null}")
        Log.d(TAG, "onCreateInputView - secondaryDisplay ID: ${secondaryDisplay?.displayId}")

        return if (secondaryDisplay != null) {
            // Secondary display exists - return minimal view for primary screen
            // The actual keyboard is shown on the secondary display via Presentation
            Log.d(TAG, "Using secondary display mode - returning minimal view")
            isInPrimaryFallbackMode = false
            // Return a minimal 1dp view instead of 0-height to ensure onStartInputView is called
            createEmptyView()
        } else {
            // No secondary display - render keyboard on primary with 50% max height
            Log.d(TAG, "Using primary fallback mode - rendering on primary screen")
            createPrimaryFlutterView()
        }
    }

    override fun onBindInput() {
        super.onBindInput()
        Log.d(TAG, "======= onBindInput =======")
    }

    override fun onWindowShown() {
        super.onWindowShown()
        Log.d(TAG, "======= onWindowShown =======")
    }

    /**
     * Override to always show the keyboard when there's a secondary display.
     * This is needed because we return a 0-height view on the primary screen,
     * but Android might interpret that as "no keyboard needed".
     */
    override fun onShowInputRequested(flags: Int, configChange: Boolean): Boolean {
        Log.d(TAG, "======= onShowInputRequested =======")
        Log.d(TAG, "onShowInputRequested - flags: $flags, configChange: $configChange, hasSecondary: ${secondaryDisplay != null}")
        // Always return true to ensure the keyboard is shown
        // We'll display it on the secondary display via Presentation
        return true
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        Log.d(TAG, "======= onStartInput (no view) =======")
        Log.d(TAG, "onStartInput - editorInfo: ${attribute?.packageName}, inputType: ${attribute?.inputType}")

        // If we have a secondary display, request to show the keyboard explicitly
        // This ensures onStartInputView gets called even with a 0-height primary view
        if (secondaryDisplay != null && attribute?.inputType != 0) {
            Log.d(TAG, "onStartInput - requesting keyboard show for secondary display")
            requestShowSelf(0)
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        Log.d(TAG, "======= onStartInputView START =======")
        Log.d(TAG, "onStartInputView - restarting: $restarting, primaryFallback: $isInPrimaryFallbackMode")
        Log.d(TAG, "onStartInputView - secondaryDisplay: ${secondaryDisplay?.displayId}")
        Log.d(TAG, "onStartInputView - presentation: ${presentation != null}")
        Log.d(TAG, "onStartInputView - editorInfo: ${info?.packageName}, inputType: ${info?.inputType}")

        // Notify Flutter about input connection
        notifyFlutterConnectionStatus(true)

        if (isInPrimaryFallbackMode) {
            // In primary fallback mode - ensure FlutterView is attached
            Log.d(TAG, "onStartInputView - using PRIMARY FALLBACK MODE")
            ensurePrimaryViewAttached()
            // Notify Flutter about primary fallback mode
            notifyDisplayModeChanged("primary_fallback", null)
        } else {
            // Show keyboard on secondary display if available
            Log.d(TAG, "onStartInputView - showing keyboard on SECONDARY DISPLAY")
            showKeyboardPresentation()
        }
        Log.d(TAG, "======= onStartInputView END =======")
    }

    /**
     * Ensure the primary FlutterView is attached to the engine.
     * This is needed because Android caches the input view and reuses it.
     */
    private fun ensurePrimaryViewAttached() {
        if (!isPrimaryViewAttached && primaryFlutterView != null && flutterEngine != null) {
            Log.d(TAG, "Re-attaching primary FlutterView to engine")
            try {
                primaryFlutterView?.attachToFlutterEngine(flutterEngine!!)
                isPrimaryViewAttached = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to re-attach FlutterView", e)
            }
        }
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        Log.d(TAG, "onFinishInputView - finishing: $finishingInput, primaryFallback: $isInPrimaryFallbackMode")

        // Notify Flutter about disconnection
        notifyFlutterConnectionStatus(false)

        if (isInPrimaryFallbackMode) {
            // In primary fallback mode - DON'T cleanup the view, just mark as detached
            // Android caches the input view and will reuse it
            // We'll re-attach in onStartInputView
            Log.d(TAG, "Primary fallback mode - keeping view for reuse")
            // Don't detach - keep the view attached for smooth transitions
        } else {
            // Hide keyboard presentation (secondary display mode)
            hideKeyboardPresentation()
        }
    }

    /**
     * Clean up the primary FlutterView when switching modes or destroying service.
     * This should only be called when:
     * 1. Switching from primary fallback to secondary display mode
     * 2. Service is being destroyed
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
        isPrimaryViewAttached = false
        isInPrimaryFallbackMode = false
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

        val engine = flutterEngine
        if (engine == null) {
            Log.e(TAG, "FlutterEngine is null - cannot show presentation")
            return
        }

        Log.d(TAG, "Creating keyboard presentation on display: ${display.displayId}")
        Log.d(TAG, "  Display name: ${display.name}")
        Log.d(TAG, "  Display size: ${display.mode.physicalWidth}x${display.mode.physicalHeight}")
        Log.d(TAG, "  Display state: ${display.state}")
        Log.d(TAG, "  Display valid: ${display.isValid}")

        try {
            // On Android 12+ (API 31), we need to create a WindowContext for the Presentation
            // because InputMethodService context has window type TYPE_INPUT_METHOD (2037)
            // but Presentation requires TYPE_PRESENTATION (2011)
            val presentationContext: Context = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Log.d(TAG, "Android 12+ detected, creating WindowContext for Presentation")
                // TYPE_PRESENTATION = 2011
                createDisplayContext(display).createWindowContext(
                    2011,
                    null
                )
            } else {
                this
            }

            presentation = VirtualKeyboardPresentation(
                presentationContext,
                display,
                engine,
                onEngineReady = { localEngine ->
                    // Set up MethodChannel on the Presentation's local engine
                    // This allows the Flutter keyboard UI to communicate with the IME service
                    Log.d(TAG, "Presentation engine ready, setting up MethodChannel")
                    setupMethodChannelOnEngine(localEngine)
                }
            ).apply {
                Log.d(TAG, "Calling presentation.show()")
                show()
                Log.d(TAG, "Presentation shown successfully, isShowing: $isShowing")
                // Notify Flutter we're in secondary display mode
                notifyDisplayModeChanged("secondary", display)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show presentation: ${e.message}", e)
            // Log crash with display state
            CrashLogger.logException(
                context = this@TeleDeckIMEService,
                exception = e,
                displayState = getDisplayState(),
                engineState = "running"
            )
            presentation = null
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
        Log.d(TAG, "toggleKeyboard - primaryFallback: $isInPrimaryFallbackMode, hasSecondary: ${secondaryDisplay != null}")
        if (secondaryDisplay != null) {
            // Secondary display mode - toggle presentation
            if (presentation != null) {
                hideKeyboardPresentation()
            } else {
                showKeyboardPresentation()
            }
        } else {
            // Primary fallback mode - use IME framework to toggle
            // In primary mode, the keyboard visibility is managed by the system
            // We can request to show/hide via InputMethodManager
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            if (isInputViewShown) {
                requestHideSelf(0)
            } else {
                // Request to show the keyboard - this will trigger onStartInputView
                requestShowSelf(0)
            }
        }
    }

    /**
     * Show keyboard (for external triggers)
     */
    fun showKeyboard() {
        Log.d(TAG, "showKeyboard - primaryFallback: $isInPrimaryFallbackMode")
        if (secondaryDisplay != null) {
            showKeyboardPresentation()
        } else {
            // Primary fallback mode - request show via IME framework
            requestShowSelf(0)
        }
    }

    /**
     * Hide keyboard (for external triggers)
     */
    fun hideKeyboard() {
        Log.d(TAG, "hideKeyboard - primaryFallback: $isInPrimaryFallbackMode")
        if (secondaryDisplay != null) {
            hideKeyboardPresentation()
        } else {
            // Primary fallback mode - request hide via IME framework
            requestHideSelf(0)
        }
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
