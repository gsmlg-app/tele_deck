package com.tele.tele_presentation

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.WindowManager
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Base class for rendering Flutter content on a secondary display.
 *
 * This presentation creates a local FlutterEngine tied to the display context,
 * which is required because FlutterEngine rendering is tied to its creation context.
 *
 * Key features:
 * - Creates local FlutterEngine with proper display context
 * - Sets window flags to prevent stealing focus from primary display
 * - Manages FlutterView lifecycle
 * - Provides hooks for subclasses to set up MethodChannel communication
 *
 * Usage:
 * ```kotlin
 * class MyPresentation(
 *     context: Context,
 *     display: Display,
 *     dartEntrypoint: String
 * ) : FlutterPresentation(context, display, dartEntrypoint) {
 *
 *     override fun onEngineReady(engine: FlutterEngine) {
 *         // Set up MethodChannel communication
 *         MethodChannel(engine.dartExecutor.binaryMessenger, "my_channel")
 *             .setMethodCallHandler { call, result ->
 *                 // Handle calls
 *             }
 *     }
 * }
 * ```
 */
abstract class FlutterPresentation(
    outerContext: Context,
    display: Display,
    private val dartEntrypoint: String = "main"
) : Presentation(createPresentationContext(outerContext, display), display) {

    companion object {
        private const val TAG = "FlutterPresentation"

        /**
         * Creates a proper window context for the presentation.
         * On Android 12+, uses createWindowContext for proper display context.
         */
        private fun createPresentationContext(context: Context, display: Display): Context {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                context.createDisplayContext(display)
                    .createWindowContext(WindowManager.LayoutParams.TYPE_PRESENTATION, null)
            } else {
                context.createDisplayContext(display)
            }
        }
    }

    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var isDartEntrypointExecuted = false
    private var container: FrameLayout? = null

    /**
     * Called when the FlutterEngine is ready and Dart code has started.
     * Override this to set up MethodChannel communication.
     */
    protected abstract fun onEngineReady(engine: FlutterEngine)

    /**
     * Called when the presentation is being dismissed.
     * Override to perform cleanup before the engine is destroyed.
     */
    protected open fun onPresentationDismissing() {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate: Creating presentation for display ${display.displayId}")

        // Set window flags to prevent stealing focus from primary display
        window?.apply {
            setFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )
        }

        // Create container for FlutterView
        container = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        setContentView(container)

        // Initialize Flutter engine with presentation context
        initFlutterEngine()
    }

    private fun initFlutterEngine() {
        Log.d(TAG, "initFlutterEngine: Creating engine for display ${display.displayId}")

        // Create engine with the presentation's context (tied to this display)
        flutterEngine = FlutterEngine(context).also { engine ->
            // Create FlutterView and attach to engine
            flutterView = FlutterView(context).also { view ->
                view.attachToFlutterEngine(engine)
                container?.addView(view, FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ))
            }

            // Execute Dart entrypoint
            if (!isDartEntrypointExecuted) {
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                        .let { default ->
                            if (dartEntrypoint == "main") {
                                default
                            } else {
                                DartExecutor.DartEntrypoint(
                                    default.pathToBundle,
                                    dartEntrypoint
                                )
                            }
                        }
                )
                isDartEntrypointExecuted = true
                Log.d(TAG, "Dart entrypoint '$dartEntrypoint' executed")
            }

            // Notify subclass that engine is ready
            onEngineReady(engine)
        }
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "onStart: Resuming engine lifecycle")
        flutterEngine?.lifecycleChannel?.appIsResumed()
    }

    override fun onStop() {
        Log.d(TAG, "onStop: Pausing engine lifecycle")
        flutterEngine?.lifecycleChannel?.appIsPaused()
        super.onStop()
    }

    override fun dismiss() {
        Log.d(TAG, "dismiss: Cleaning up presentation")
        onPresentationDismissing()
        cleanupFlutterEngine()
        super.dismiss()
    }

    private fun cleanupFlutterEngine() {
        flutterView?.let { view ->
            view.detachFromFlutterEngine()
            container?.removeView(view)
        }
        flutterView = null

        flutterEngine?.destroy()
        flutterEngine = null

        isDartEntrypointExecuted = false
        Log.d(TAG, "Flutter engine cleaned up")
    }

    /**
     * Get the current FlutterEngine, if available.
     */
    protected fun getFlutterEngine(): FlutterEngine? = flutterEngine

    /**
     * Get the display information.
     */
    fun getDisplayInfo(): DisplayInfo {
        return DisplayInfo(
            displayId = display.displayId,
            name = display.name,
            width = display.width,
            height = display.height,
            rotation = display.rotation,
            isValid = display.isValid
        )
    }

    /**
     * Data class containing display information.
     */
    data class DisplayInfo(
        val displayId: Int,
        val name: String,
        val width: Int,
        val height: Int,
        val rotation: Int,
        val isValid: Boolean
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "displayId" to displayId,
            "name" to name,
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "isValid" to isValid
        )
    }
}
