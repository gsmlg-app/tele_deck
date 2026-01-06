package com.tele.tele_ime

import android.content.Intent
import android.inputmethodservice.InputMethodService
import android.util.Log
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Base class for Flutter-based Input Method Service.
 *
 * Provides:
 * - FlutterEngine lifecycle management
 * - FlutterView attachment for keyboard rendering
 * - MethodChannel for keyboard operations (commit text, backspace, etc.)
 * - Primary fallback mode support
 *
 * Subclasses should:
 * 1. Override [getDartEntrypoint] to specify the Dart entry point
 * 2. Override [onSetupMethodChannel] to add custom MethodChannel handlers
 * 3. Optionally override [getKeyboardHeight] to customize keyboard height
 *
 * For dual-screen support, subclasses can:
 * 1. Detect secondary displays using DisplayHelper from tele_presentation
 * 2. Create a FlutterPresentation subclass for secondary display rendering
 * 3. Return 0 from [getKeyboardHeight] when rendering on secondary display
 */
abstract class BaseImeService : InputMethodService() {

    companion object {
        private const val TAG = "BaseImeService"
        const val IME_CHANNEL_NAME = "tele_ime"
    }

    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var imeMethodChannel: MethodChannel? = null
    private var isDartEntrypointExecuted = false
    private var isViewAttached = false
    private var container: FrameLayout? = null

    /**
     * Get the Dart entry point for the keyboard UI.
     * Default is "main", override to use a different entry point.
     */
    protected open fun getDartEntrypoint(): String = "main"

    /**
     * Get the keyboard height in pixels.
     * Return 0 to hide the keyboard (e.g., when rendering on secondary display).
     * Return null to use the default system height.
     */
    protected open fun getKeyboardHeight(): Int? = null

    /**
     * Called when the FlutterEngine and MethodChannel are ready.
     * Override to set up additional MethodChannel handlers.
     */
    protected open fun onSetupMethodChannel(channel: MethodChannel) {}

    /**
     * Called when input starts on a new editor.
     */
    protected open fun onInputStarted(editorInfo: EditorInfo) {}

    /**
     * Called when input finishes.
     */
    protected open fun onInputFinished() {}

    /**
     * Get the current MethodChannel for IME operations.
     */
    protected fun getImeChannel(): MethodChannel? = imeMethodChannel

    /**
     * Get the current FlutterEngine.
     */
    protected fun getFlutterEngine(): FlutterEngine? = flutterEngine

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Initializing IME service")
        initFlutterEngine()
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: Cleaning up IME service")
        cleanupFlutterEngine()
        super.onDestroy()
    }

    private fun initFlutterEngine() {
        Log.d(TAG, "initFlutterEngine: Creating engine")

        flutterEngine = FlutterEngine(this).also { engine ->
            // Set up MethodChannel before executing Dart
            imeMethodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, IME_CHANNEL_NAME).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "commitText" -> {
                            val text = call.argument<String>("text") ?: ""
                            commitText(text)
                            result.success(null)
                        }
                        "backspace" -> {
                            performBackspace()
                            result.success(null)
                        }
                        "delete" -> {
                            performDelete()
                            result.success(null)
                        }
                        "enter" -> {
                            performEnter()
                            result.success(null)
                        }
                        "tab" -> {
                            performTab()
                            result.success(null)
                        }
                        "moveCursor" -> {
                            val offset = call.argument<Int>("offset") ?: 0
                            moveCursor(offset)
                            result.success(null)
                        }
                        "sendKeyEvent" -> {
                            val keyCode = call.argument<Int>("keyCode") ?: 0
                            val metaState = call.argument<Int>("metaState") ?: 0
                            sendKeyEvent(keyCode, metaState)
                            result.success(null)
                        }
                        "hideKeyboard" -> {
                            hideKeyboard()
                            result.success(null)
                        }
                        "getEditorInfo" -> {
                            result.success(getEditorInfoMap())
                        }
                        else -> {
                            // Allow subclass to handle custom methods
                            result.notImplemented()
                        }
                    }
                }

                // Let subclass set up additional handlers
                onSetupMethodChannel(channel)
            }
        }
    }

    private fun cleanupFlutterEngine() {
        detachFlutterView()
        flutterEngine?.destroy()
        flutterEngine = null
        imeMethodChannel = null
        isDartEntrypointExecuted = false
    }

    override fun onCreateInputView(): View {
        Log.d(TAG, "onCreateInputView")

        // Create container for FlutterView
        container = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                getKeyboardHeight() ?: FrameLayout.LayoutParams.WRAP_CONTENT
            )
        }

        return container!!
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        Log.d(TAG, "onStartInputView: restarting=$restarting")

        attachFlutterView()
        onInputStarted(info)

        // Notify Dart that input started
        imeMethodChannel?.invokeMethod("onInputStarted", mapOf(
            "inputType" to info.inputType,
            "imeOptions" to info.imeOptions,
            "packageName" to (info.packageName ?: ""),
            "fieldId" to info.fieldId,
            "fieldName" to (info.fieldName?.toString() ?: "")
        ))
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        Log.d(TAG, "onFinishInputView: finishingInput=$finishingInput")
        onInputFinished()

        // Notify Dart that input finished
        imeMethodChannel?.invokeMethod("onInputFinished", null)

        super.onFinishInputView(finishingInput)
    }

    private fun attachFlutterView() {
        val engine = flutterEngine ?: return
        val cont = container ?: return

        if (isViewAttached) {
            Log.d(TAG, "FlutterView already attached")
            return
        }

        Log.d(TAG, "attachFlutterView: Attaching view to engine")

        flutterView = FlutterView(this).also { view ->
            view.attachToFlutterEngine(engine)
            cont.addView(view, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
            isViewAttached = true
        }

        // Execute Dart entrypoint after view is attached
        if (!isDartEntrypointExecuted) {
            executeDartEntrypoint()
        }

        // Resume lifecycle
        engine.lifecycleChannel.appIsResumed()
    }

    private fun detachFlutterView() {
        flutterView?.let { view ->
            flutterEngine?.lifecycleChannel?.appIsPaused()
            view.detachFromFlutterEngine()
            container?.removeView(view)
        }
        flutterView = null
        isViewAttached = false
    }

    private fun executeDartEntrypoint() {
        val engine = flutterEngine ?: return
        val entrypoint = getDartEntrypoint()

        Log.d(TAG, "executeDartEntrypoint: $entrypoint")

        val dartEntrypoint = if (entrypoint == "main") {
            DartExecutor.DartEntrypoint.createDefault()
        } else {
            DartExecutor.DartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault().pathToBundle,
                entrypoint
            )
        }

        engine.dartExecutor.executeDartEntrypoint(dartEntrypoint)
        isDartEntrypointExecuted = true
    }

    // IME Operations

    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun performBackspace() {
        currentInputConnection?.deleteSurroundingText(1, 0)
    }

    private fun performDelete() {
        currentInputConnection?.deleteSurroundingText(0, 1)
    }

    private fun performEnter() {
        val ic = currentInputConnection ?: return
        val editorInfo = currentInputEditorInfo

        // Check if editor expects action on enter
        val action = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: 0
        if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
            ic.performEditorAction(action)
        } else {
            ic.commitText("\n", 1)
        }
    }

    private fun performTab() {
        currentInputConnection?.commitText("\t", 1)
    }

    private fun moveCursor(offset: Int) {
        val ic = currentInputConnection ?: return
        val selection = ic.getExtractedText(null, 0)?.selectionStart ?: 0
        ic.setSelection(selection + offset, selection + offset)
    }

    private fun sendKeyEvent(keyCode: Int, metaState: Int) {
        val ic = currentInputConnection ?: return
        val eventTime = android.os.SystemClock.uptimeMillis()

        ic.sendKeyEvent(android.view.KeyEvent(
            eventTime, eventTime,
            android.view.KeyEvent.ACTION_DOWN,
            keyCode, 0, metaState
        ))
        ic.sendKeyEvent(android.view.KeyEvent(
            eventTime, eventTime,
            android.view.KeyEvent.ACTION_UP,
            keyCode, 0, metaState
        ))
    }

    private fun hideKeyboard() {
        requestHideSelf(0)
    }

    private fun getEditorInfoMap(): Map<String, Any?> {
        val info = currentInputEditorInfo ?: return emptyMap()
        return mapOf(
            "inputType" to info.inputType,
            "imeOptions" to info.imeOptions,
            "packageName" to info.packageName,
            "fieldId" to info.fieldId,
            "fieldName" to info.fieldName?.toString()
        )
    }
}
