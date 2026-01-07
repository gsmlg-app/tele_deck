package app.gsmlg.tele_deck

import android.app.Presentation
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Presentation class for displaying the Flutter keyboard on a secondary display.
 *
 * This class extends Android's Presentation API to render content on external
 * displays. It attaches the cached FlutterEngine to a FlutterView for rendering
 * the Cyberpunk keyboard UI.
 */
class VirtualKeyboardPresentation(
    context: Context,
    display: Display,
    private val sharedFlutterEngine: FlutterEngine,
    private val onEngineReady: ((FlutterEngine) -> Unit)? = null
) : Presentation(context, display) {

    companion object {
        private const val TAG = "VirtualKeyboardPresentation"
        // Local FlutterEngine for this presentation's display context
        private var localFlutterEngine: FlutterEngine? = null
        private var isDartEntrypointExecuted: Boolean = false

        // Keep track of whether presentation is currently showing
        // This allows the IME service to detect and reuse an existing presentation
        private var isCurrentlyShowing: Boolean = false

        fun isShowing(): Boolean = isCurrentlyShowing
    }

    /**
     * Get the local FlutterEngine used by this Presentation.
     * This can be used to set up MethodChannels for communication.
     */
    fun getLocalEngine(): FlutterEngine? = localFlutterEngine

    private var flutterView: FlutterView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "VirtualKeyboardPresentation onCreate")

        // Configure window for keyboard presentation on secondary display
        // NOTE: The window type is inherited from the WindowContext passed to the constructor.
        // Do NOT set the window type here - it must match the context's window type.
        window?.let { window ->
            Log.d(TAG, "Configuring window for display: ${display.displayId}")
            Log.d(TAG, "Window type from context (should be TYPE_APPLICATION_OVERLAY)")

            // Make the presentation fullscreen on the secondary display
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )

            // CRITICAL: Prevent the keyboard from stealing focus from primary display
            // FLAG_NOT_FOCUSABLE - Key events go to primary display app, not keyboard
            // FLAG_NOT_TOUCH_MODAL - Touch events outside keyboard pass through
            // Without these flags, touching keyboard steals focus → onFinishInputView → keyboard disappears
            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )
            Log.d(TAG, "Added FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL to prevent focus stealing")

            // Set hardware acceleration
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)

            // Keep screen on while keyboard is displayed
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

            // Set window format to OPAQUE for proper rendering
            // This ensures the Flutter content is visible instead of being transparent
            window.setFormat(PixelFormat.OPAQUE)

            // Set a dark background to ensure visibility
            window.setBackgroundDrawableResource(android.R.color.black)

            // Also set the decor view background
            window.decorView.setBackgroundColor(Color.BLACK)

            // Log window details for debugging
            val attrs = window.attributes
            Log.d(TAG, "Window configured - type=${attrs.type}, format=${attrs.format}, flags=${attrs.flags}")
            Log.d(TAG, "Window base layer should be above SecondaryLauncher")
        } ?: Log.e(TAG, "Window is null - cannot configure presentation")

        // Create and attach FlutterView
        createFlutterView()
    }

    private var isAttachedToEngine = false

    private fun createFlutterView() {
        Log.d(TAG, "Creating FlutterView with LOCAL FlutterEngine for Presentation")
        isAttachedToEngine = false

        // Create a local FlutterEngine for this Presentation's display context
        // This is important because FlutterEngine rendering is tied to its creation context
        if (localFlutterEngine == null) {
            Log.d(TAG, "Creating new local FlutterEngine for Presentation display")
            localFlutterEngine = FlutterEngine(context)
        }
        val engine = localFlutterEngine!!

        // Create FlutterView with default SurfaceView
        val view = FlutterView(context)
        Log.d(TAG, "FlutterView created with default SurfaceView")

        // NOTE: Do not set focusable=true since window has FLAG_NOT_FOCUSABLE.
        // Touch events work without focus, and keeping focus on primary display
        // is critical for the IME to receive input.
        view.isFocusable = false
        view.isFocusableInTouchMode = false
        view.isClickable = true  // Still allow click/touch events
        Log.d(TAG, "FlutterView configured: focusable=false (FLAG_NOT_FOCUSABLE), clickable=true")

        flutterView = view

        // Set the view as content view
        setContentView(view)

        // Add layout listener to track view dimensions
        view.viewTreeObserver.addOnGlobalLayoutListener {
            Log.d(TAG, "FlutterView layout: width=${view.width}, height=${view.height}")
        }

        // Attach to engine when added to hierarchy
        view.addOnAttachStateChangeListener(object : android.view.View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: android.view.View) {
                Log.d(TAG, "FlutterView attached to window - attaching to LOCAL FlutterEngine")

                if (!isAttachedToEngine) {
                    // Execute Dart entrypoint BEFORE attaching to ensure engine is ready
                    if (!isDartEntrypointExecuted) {
                        Log.d(TAG, "Executing Dart entrypoint: imeMain on local engine")
                        val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                        engine.dartExecutor.executeDartEntrypoint(
                            DartExecutor.DartEntrypoint(appBundlePath, "imeMain")
                        )
                        isDartEntrypointExecuted = true
                    }

                    // Attach FlutterView to the LOCAL FlutterEngine
                    // This uses attachToFlutterEngine which has better integration than attachToRenderer
                    view.attachToFlutterEngine(engine)
                    isAttachedToEngine = true

                    Log.d(TAG, "FlutterView attached to local FlutterEngine")

                    // Notify that engine is ready - caller can set up MethodChannels
                    onEngineReady?.invoke(engine)

                    // Notify Flutter lifecycle that app is resumed to trigger rendering
                    engine.lifecycleChannel.appIsResumed()

                    Log.d(TAG, "Local FlutterEngine lifecycle resumed")

                    // NOTE: Do NOT request focus for the view or decor view.
                    // The window has FLAG_NOT_FOCUSABLE set, so focus must stay on
                    // the primary display app. Touch events still work without focus.
                    Log.d(TAG, "FlutterView attached (not requesting focus - FLAG_NOT_FOCUSABLE)")
                }
            }

            override fun onViewDetachedFromWindow(v: android.view.View) {
                Log.d(TAG, "FlutterView detached from window")
                if (isAttachedToEngine) {
                    view.detachFromFlutterEngine()
                    isAttachedToEngine = false
                }
            }
        })

        Log.d(TAG, "FlutterView created with local engine, waiting for window attachment")
    }

    override fun dispatchTouchEvent(event: android.view.MotionEvent): Boolean {
        Log.d(TAG, "dispatchTouchEvent: action=${event.actionMasked}, x=${event.x}, y=${event.y}")
        return super.dispatchTouchEvent(event)
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "VirtualKeyboardPresentation onStart, isAttachedToEngine=$isAttachedToEngine")

        // Bring the window to front to ensure it's on top of other overlays
        window?.let { window ->
            Log.d(TAG, "Bringing window to front")
            window.decorView.bringToFront()

            // Also try setting the window as always on top
            val layoutParams = window.attributes
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                // Use a flag to indicate this should be on top
                layoutParams.flags = layoutParams.flags or
                    WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
            }
            window.attributes = layoutParams
        }
    }

    override fun onStop() {
        Log.d(TAG, "VirtualKeyboardPresentation onStop")
        super.onStop()
    }

    override fun dismiss() {
        Log.d(TAG, "VirtualKeyboardPresentation dismiss")

        // Detach FlutterView from engine before dismissing
        flutterView?.let { view ->
            try {
                if (isAttachedToEngine) {
                    view.detachFromFlutterEngine()
                    isAttachedToEngine = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error detaching FlutterView", e)
            }
        }

        // Destroy the local engine completely to ensure fresh state on next show
        // This fixes the issue where reusing the engine with a new FlutterView
        // doesn't render the Flutter UI properly
        localFlutterEngine?.let { engine ->
            Log.d(TAG, "Destroying local FlutterEngine on dismiss")
            try {
                engine.lifecycleChannel.appIsPaused()
                engine.destroy()
            } catch (e: Exception) {
                Log.e(TAG, "Error destroying FlutterEngine", e)
            }
        }
        localFlutterEngine = null
        isDartEntrypointExecuted = false

        flutterView = null
        super.dismiss()
    }
}
