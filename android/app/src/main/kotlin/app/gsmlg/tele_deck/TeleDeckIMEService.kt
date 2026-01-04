package app.gsmlg.tele_deck

import android.content.Context
import android.hardware.display.DisplayManager
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
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

        // Singleton reference for the broadcast receiver
        var instance: TeleDeckIMEService? = null
            private set
    }

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var presentation: VirtualKeyboardPresentation? = null
    private var displayManager: DisplayManager? = null
    private var secondaryDisplay: Display? = null

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
            Log.d(TAG, "Creating new FlutterEngine")
            flutterEngine = FlutterEngine(this).apply {
                // Execute the Dart entrypoint
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
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
            Log.d(TAG, "Display added: $displayId")
            val display = displayManager?.getDisplay(displayId)
            if (display != null && displayId != Display.DEFAULT_DISPLAY) {
                secondaryDisplay = display
                // If input is active, show presentation on new display
                if (presentation == null) {
                    showKeyboardPresentation()
                }
            }
        }

        override fun onDisplayRemoved(displayId: Int) {
            Log.d(TAG, "Display removed: $displayId")
            if (secondaryDisplay?.displayId == displayId) {
                hideKeyboardPresentation()
                secondaryDisplay = null
            }
        }

        override fun onDisplayChanged(displayId: Int) {
            // Handle display changes if needed
        }
    }

    override fun onCreateInputView(): View {
        Log.d(TAG, "onCreateInputView")
        // Return a 0-height view for the primary screen
        // The actual keyboard is shown on the secondary display via Presentation
        return FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0  // 0-height to not take space on primary screen
            )
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

        // Hide keyboard presentation
        hideKeyboardPresentation()
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
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to show presentation", e)
                    presentation = null
                }
            }
        }
    }

    private fun hideKeyboardPresentation() {
        presentation?.let {
            Log.d(TAG, "Hiding keyboard presentation")
            try {
                it.dismiss()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to dismiss presentation", e)
            }
        }
        presentation = null
    }

    private fun notifyFlutterConnectionStatus(connected: Boolean) {
        methodChannel?.invokeMethod("connectionStatus", mapOf("connected" to connected))
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

        // Clean up display listener
        displayManager?.unregisterDisplayListener(displayListener)

        // Clean up presentation
        hideKeyboardPresentation()

        // Don't destroy the FlutterEngine - it's cached for reuse
        // FlutterEngineCache handles cleanup

        super.onDestroy()
    }
}
