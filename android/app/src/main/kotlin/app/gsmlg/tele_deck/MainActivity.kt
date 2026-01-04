package app.gsmlg.tele_deck

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.gsmlg.tele_deck/keyboard_toggle"
        var toggleKeyboardChannel: MethodChannel? = null
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
