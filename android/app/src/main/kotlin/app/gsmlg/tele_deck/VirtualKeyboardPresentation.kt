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
        // NOTE: Do NOT use TYPE_INPUT_METHOD here - it's only valid for primary display IME
        // Presentation windows manage their own window type internally
        window?.let { window ->
            Log.d(TAG, "Configuring window for display: ${display.displayId}")

            // ============================================================
            // CRITICAL: Prevent focus stealing from primary display
            // ============================================================
            // FLAG_NOT_FOCUSABLE: Window won't get key input focus
            //   - Key events go to focusable window behind it (primary display)
            //   - Implicitly enables FLAG_NOT_TOUCH_MODAL
            //   - Window still receives touch events for keyboard interaction
            //
            // FLAG_NOT_TOUCH_MODAL: Allows touch events outside window
            //   to pass through to windows behind (primary display apps)
            //
            // This is essential for IME on secondary display - without these flags,
            // touching the keyboard would steal focus from the primary display app,
            // causing onFinishInputView to be called and the keyboard to disappear.
            // ============================================================
            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            )
            Log.d(TAG, "Window flags set: FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL")

            // Make the presentation fullscreen on the secondary display
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )

            // Set hardware acceleration
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)

            // Keep screen on while keyboard is displayed
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

            // Set window format to OPAQUE for proper rendering
            // This ensures the Flutter content is visible instead of being transparent
            window.setFormat(PixelFormat.OPAQUE)

            // Set a dark background to ensure visibility
            window.setBackgroundDrawableResource(android.R.color.black)

            Log.d(TAG, "Window configured successfully with OPAQUE format")
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

        // Create FlutterTextureView for better secondary display compatibility
        // FlutterTextureView uses TextureView which works better with window compositing
        // on secondary displays compared to FlutterSurfaceView
        // NOTE: TextureView doesn't support background drawables, so we can't set a background color
        val textureView = FlutterTextureView(context)
        Log.d(TAG, "FlutterTextureView created for secondary display")

        // Create FlutterView wrapping the TextureView
        val view = FlutterView(context, textureView)
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

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "VirtualKeyboardPresentation onStart, isAttachedToEngine=$isAttachedToEngine")

        // Don't attach here - let the post callback handle it to ensure surface is ready
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
