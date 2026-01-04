package app.gsmlg.tele_deck

import android.view.Display
import com.hcoderlee.subscreen.sub_screen.FlutterPresentation
import com.hcoderlee.subscreen.sub_screen.MultiDisplayFlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : MultiDisplayFlutterActivity() {

    companion object {
        private const val CHANNEL = "app.gsmlg.tele_deck/keyboard_toggle"
        var toggleKeyboardChannel: MethodChannel? = null
    }

    /**
     * Returns the name of the Flutter entry point function for the secondary display.
     * This function must be annotated with @pragma('vm:entry-point') in Flutter code.
     */
    override fun getSubScreenEntryPoint(): String {
        return "keyboardEntry"
    }

    /**
     * Override to provide custom presentation behavior if needed
     */
    override fun createSubScreenPresentation(display: Display): FlutterPresentation? {
        return null  // Use default presentation
    }

    /**
     * Called when the secondary display is launched and ready
     */
    override fun onLaunchSubScreen(display: Display) {
        super.onLaunchSubScreen(display)
        // Notify Flutter that secondary screen is ready
        toggleKeyboardChannel?.invokeMethod("secondaryDisplayReady", display.displayId)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for keyboard toggle commands
        toggleKeyboardChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onDestroy() {
        toggleKeyboardChannel = null
        super.onDestroy()
    }
}
