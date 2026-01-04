package app.gsmlg.tele_deck

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine

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
    private val flutterEngine: FlutterEngine
) : Presentation(context, display) {

    companion object {
        private const val TAG = "VirtualKeyboardPresentation"
    }

    private var flutterView: FlutterView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "VirtualKeyboardPresentation onCreate")

        // Configure window for keyboard presentation
        window?.let { window ->
            // Set window type for IME
            window.setType(WindowManager.LayoutParams.TYPE_INPUT_METHOD)

            // Make the presentation fullscreen on the secondary display
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_FULLSCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )

            // Set hardware acceleration
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)

            // Keep screen on while keyboard is displayed
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }

        // Create and attach FlutterView
        createFlutterView()
    }

    private fun createFlutterView() {
        Log.d(TAG, "Creating FlutterView")

        // Create FlutterView and attach the engine
        val view = FlutterView(context).apply {
            // Attach to the FlutterEngine
            attachToFlutterEngine(flutterEngine)
        }
        flutterView = view

        // Set the FlutterView as the content view
        setContentView(view)

        Log.d(TAG, "FlutterView created and attached")
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "VirtualKeyboardPresentation onStart")

        // Ensure FlutterView is properly attached
        flutterView?.let { view ->
            if (!view.isAttachedToFlutterEngine) {
                view.attachToFlutterEngine(flutterEngine)
            }
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
                if (view.isAttachedToFlutterEngine) {
                    view.detachFromFlutterEngine()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error detaching FlutterView", e)
            }
        }

        flutterView = null
        super.dismiss()
    }
}
