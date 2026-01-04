package app.gsmlg.tele_deck

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver that handles the keyboard toggle action.
 *
 * This receiver responds to the action: app.gsmlg.tele_deck.TOGGLE_KEYBOARD
 *
 * Ayaneo Pocket DS (or other devices) can bind a physical button to send this broadcast:
 * adb shell am broadcast -a app.gsmlg.tele_deck.TOGGLE_KEYBOARD
 */
class ToggleKeyboardReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE_KEYBOARD = "app.gsmlg.tele_deck.TOGGLE_KEYBOARD"
        const val ACTION_SHOW_KEYBOARD = "app.gsmlg.tele_deck.SHOW_KEYBOARD"
        const val ACTION_HIDE_KEYBOARD = "app.gsmlg.tele_deck.HIDE_KEYBOARD"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE_KEYBOARD -> {
                // Notify the main activity to toggle keyboard
                MainActivity.toggleKeyboardChannel?.invokeMethod("toggleKeyboard", null)
            }
            ACTION_SHOW_KEYBOARD -> {
                MainActivity.toggleKeyboardChannel?.invokeMethod("showKeyboard", null)
            }
            ACTION_HIDE_KEYBOARD -> {
                MainActivity.toggleKeyboardChannel?.invokeMethod("hideKeyboard", null)
            }
        }
    }
}
