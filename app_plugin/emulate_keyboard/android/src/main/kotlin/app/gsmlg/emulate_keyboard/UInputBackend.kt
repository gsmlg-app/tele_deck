package app.gsmlg.emulate_keyboard

import android.content.Context
import android.util.Log
import android.view.KeyEvent
import java.io.DataOutputStream
import java.io.File

/**
 * uinput backend for keyboard emulation.
 *
 * Uses Linux uinput kernel module to create a virtual input device
 * that is indistinguishable from real hardware.
 *
 * Requirements:
 * - Root access (su)
 * - /dev/uinput accessible
 */
class UInputBackend(private val context: Context) : IKeyboardBackend {

    companion object {
        private const val TAG = "UInputBackend"

        // Load native library
        init {
            try {
                System.loadLibrary("uinput_keyboard")
                Log.d(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e)
            }
        }

        // === Linux keycodes (from linux/input-event-codes.h) ===
        const val KEY_ESC = 1
        const val KEY_1 = 2
        const val KEY_2 = 3
        const val KEY_3 = 4
        const val KEY_4 = 5
        const val KEY_5 = 6
        const val KEY_6 = 7
        const val KEY_7 = 8
        const val KEY_8 = 9
        const val KEY_9 = 10
        const val KEY_0 = 11
        const val KEY_MINUS = 12
        const val KEY_EQUAL = 13
        const val KEY_BACKSPACE = 14
        const val KEY_TAB = 15
        const val KEY_Q = 16
        const val KEY_W = 17
        const val KEY_E = 18
        const val KEY_R = 19
        const val KEY_T = 20
        const val KEY_Y = 21
        const val KEY_U = 22
        const val KEY_I = 23
        const val KEY_O = 24
        const val KEY_P = 25
        const val KEY_LEFTBRACE = 26
        const val KEY_RIGHTBRACE = 27
        const val KEY_ENTER = 28
        const val KEY_LEFTCTRL = 29
        const val KEY_A = 30
        const val KEY_S = 31
        const val KEY_D = 32
        const val KEY_F = 33
        const val KEY_G = 34
        const val KEY_H = 35
        const val KEY_J = 36
        const val KEY_K = 37
        const val KEY_L = 38
        const val KEY_SEMICOLON = 39
        const val KEY_APOSTROPHE = 40
        const val KEY_GRAVE = 41
        const val KEY_LEFTSHIFT = 42
        const val KEY_BACKSLASH = 43
        const val KEY_Z = 44
        const val KEY_X = 45
        const val KEY_C = 46
        const val KEY_V = 47
        const val KEY_B = 48
        const val KEY_N = 49
        const val KEY_M = 50
        const val KEY_COMMA = 51
        const val KEY_DOT = 52
        const val KEY_SLASH = 53
        const val KEY_RIGHTSHIFT = 54
        const val KEY_LEFTALT = 56
        const val KEY_SPACE = 57
        const val KEY_CAPSLOCK = 58
        const val KEY_F1 = 59
        const val KEY_F2 = 60
        const val KEY_F3 = 61
        const val KEY_F4 = 62
        const val KEY_F5 = 63
        const val KEY_F6 = 64
        const val KEY_F7 = 65
        const val KEY_F8 = 66
        const val KEY_F9 = 67
        const val KEY_F10 = 68
        const val KEY_F11 = 87
        const val KEY_F12 = 88
        const val KEY_RIGHTCTRL = 97
        const val KEY_RIGHTALT = 100
        const val KEY_HOME = 102
        const val KEY_UP = 103
        const val KEY_PAGEUP = 104
        const val KEY_LEFT = 105
        const val KEY_RIGHT = 106
        const val KEY_END = 107
        const val KEY_DOWN = 108
        const val KEY_PAGEDOWN = 109
        const val KEY_INSERT = 110
        const val KEY_DELETE = 111
        const val KEY_LEFTMETA = 125
        const val KEY_RIGHTMETA = 126
    }

    override var isAvailable: Boolean = false
        private set

    override var isInitialized: Boolean = false
        private set

    override val isConnected: Boolean
        get() = isInitialized && nativeIsConnected()

    private var hasRootAccess: Boolean = false
    private var statusMessage: String = ""
    private var errorMessage: String? = null

    init {
        checkAvailability()
    }

    private fun checkAvailability() {
        // Check if /dev/uinput exists
        val uinputFile = File("/dev/uinput")
        val inputFile = File("/dev/input/uinput")

        val uinputExists = uinputFile.exists() || inputFile.exists()

        if (!uinputExists) {
            statusMessage = "uinput device not found"
            isAvailable = false
            return
        }

        // Check if native library is loaded
        try {
            nativeIsAvailable()
            statusMessage = "Available (requires root)"
            isAvailable = true
        } catch (e: UnsatisfiedLinkError) {
            statusMessage = "Native library not loaded"
            errorMessage = e.message
            isAvailable = false
        }
    }

    override fun initialize(): Boolean {
        if (!isAvailable) {
            Log.w(TAG, "uinput not available")
            return false
        }

        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        // Check/request root access
        if (!hasRootAccess) {
            hasRootAccess = requestRootAccess()
            if (!hasRootAccess) {
                errorMessage = "Root access denied"
                return false
            }
        }

        // Initialize native uinput device
        return try {
            val result = nativeInitialize()
            if (result) {
                isInitialized = true
                statusMessage = "Initialized with root"
                Log.d(TAG, "uinput device initialized")
            } else {
                errorMessage = "Failed to create uinput device"
            }
            result
        } catch (e: Exception) {
            errorMessage = "Native init failed: ${e.message}"
            Log.e(TAG, "Failed to initialize uinput", e)
            false
        }
    }

    override fun cleanup() {
        if (isInitialized) {
            try {
                nativeCleanup()
            } catch (e: Exception) {
                Log.w(TAG, "Error during cleanup", e)
            }
            isInitialized = false
            statusMessage = "Available (requires root)"
        }
    }

    override fun getStatus(): Map<String, Any?> {
        return mapOf(
            "backend" to "uinput",
            "isAvailable" to isAvailable,
            "isInitialized" to isInitialized,
            "isConnected" to isConnected,
            "message" to statusMessage,
            "error" to errorMessage,
            "details" to mapOf(
                "hasRoot" to hasRootAccess,
                "uinputPath" to if (File("/dev/uinput").exists()) "/dev/uinput" else "/dev/input/uinput"
            )
        )
    }

    /**
     * Check if root access is available without prompting.
     */
    fun checkRootAccess(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val exitCode = process.waitFor()
            hasRootAccess = exitCode == 0
            hasRootAccess
        } catch (e: Exception) {
            Log.d(TAG, "Root check failed: ${e.message}")
            false
        }
    }

    /**
     * Request root access (may show su dialog).
     */
    fun requestRootAccess(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("su")
            val os = DataOutputStream(process.outputStream)
            os.writeBytes("id\n")
            os.writeBytes("exit\n")
            os.flush()
            val exitCode = process.waitFor()
            hasRootAccess = exitCode == 0
            if (hasRootAccess) {
                Log.d(TAG, "Root access granted")
            } else {
                Log.w(TAG, "Root access denied")
            }
            hasRootAccess
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request root", e)
            false
        }
    }

    override fun sendKeyEvent(
        keyCode: Int,
        shift: Boolean,
        ctrl: Boolean,
        alt: Boolean,
        meta: Boolean,
        isDown: Boolean?
    ): Boolean {
        if (!isInitialized) {
            Log.w(TAG, "uinput not initialized")
            return false
        }

        return try {
            // Convert Android keycode to Linux keycode
            val linuxKeyCode = androidToLinuxKeyCode(keyCode)

            when (isDown) {
                true -> nativeSendKeyDown(linuxKeyCode)
                false -> nativeSendKeyUp(linuxKeyCode)
                null -> {
                    // Full key press with modifiers
                    if (shift) nativeSendKeyDown(KEY_LEFTSHIFT)
                    if (ctrl) nativeSendKeyDown(KEY_LEFTCTRL)
                    if (alt) nativeSendKeyDown(KEY_LEFTALT)
                    if (meta) nativeSendKeyDown(KEY_LEFTMETA)

                    nativeSendKeyDown(linuxKeyCode)
                    nativeSendKeyUp(linuxKeyCode)

                    if (meta) nativeSendKeyUp(KEY_LEFTMETA)
                    if (alt) nativeSendKeyUp(KEY_LEFTALT)
                    if (ctrl) nativeSendKeyUp(KEY_LEFTCTRL)
                    if (shift) nativeSendKeyUp(KEY_LEFTSHIFT)
                }
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send key event", e)
            false
        }
    }

    override fun typeText(text: String): Boolean {
        if (!isInitialized) return false

        for (char in text) {
            val keyInfo = charToLinuxKeyCode(char)
            if (keyInfo != null) {
                if (keyInfo.second) nativeSendKeyDown(KEY_LEFTSHIFT)
                nativeSendKeyDown(keyInfo.first)
                nativeSendKeyUp(keyInfo.first)
                if (keyInfo.second) nativeSendKeyUp(KEY_LEFTSHIFT)
                Thread.sleep(10)
            }
        }
        return true
    }

    // === Native methods ===

    private external fun nativeIsAvailable(): Boolean
    private external fun nativeIsConnected(): Boolean
    private external fun nativeInitialize(): Boolean
    private external fun nativeCleanup()
    private external fun nativeSendKeyDown(linuxKeyCode: Int)
    private external fun nativeSendKeyUp(linuxKeyCode: Int)

    /**
     * Convert Android KeyEvent keycode to Linux input keycode.
     */
    private fun androidToLinuxKeyCode(androidKeyCode: Int): Int {
        return when (androidKeyCode) {
            KeyEvent.KEYCODE_A -> KEY_A
            KeyEvent.KEYCODE_B -> KEY_B
            KeyEvent.KEYCODE_C -> KEY_C
            KeyEvent.KEYCODE_D -> KEY_D
            KeyEvent.KEYCODE_E -> KEY_E
            KeyEvent.KEYCODE_F -> KEY_F
            KeyEvent.KEYCODE_G -> KEY_G
            KeyEvent.KEYCODE_H -> KEY_H
            KeyEvent.KEYCODE_I -> KEY_I
            KeyEvent.KEYCODE_J -> KEY_J
            KeyEvent.KEYCODE_K -> KEY_K
            KeyEvent.KEYCODE_L -> KEY_L
            KeyEvent.KEYCODE_M -> KEY_M
            KeyEvent.KEYCODE_N -> KEY_N
            KeyEvent.KEYCODE_O -> KEY_O
            KeyEvent.KEYCODE_P -> KEY_P
            KeyEvent.KEYCODE_Q -> KEY_Q
            KeyEvent.KEYCODE_R -> KEY_R
            KeyEvent.KEYCODE_S -> KEY_S
            KeyEvent.KEYCODE_T -> KEY_T
            KeyEvent.KEYCODE_U -> KEY_U
            KeyEvent.KEYCODE_V -> KEY_V
            KeyEvent.KEYCODE_W -> KEY_W
            KeyEvent.KEYCODE_X -> KEY_X
            KeyEvent.KEYCODE_Y -> KEY_Y
            KeyEvent.KEYCODE_Z -> KEY_Z
            KeyEvent.KEYCODE_0 -> KEY_0
            KeyEvent.KEYCODE_1 -> KEY_1
            KeyEvent.KEYCODE_2 -> KEY_2
            KeyEvent.KEYCODE_3 -> KEY_3
            KeyEvent.KEYCODE_4 -> KEY_4
            KeyEvent.KEYCODE_5 -> KEY_5
            KeyEvent.KEYCODE_6 -> KEY_6
            KeyEvent.KEYCODE_7 -> KEY_7
            KeyEvent.KEYCODE_8 -> KEY_8
            KeyEvent.KEYCODE_9 -> KEY_9
            KeyEvent.KEYCODE_SPACE -> KEY_SPACE
            KeyEvent.KEYCODE_ENTER -> KEY_ENTER
            KeyEvent.KEYCODE_TAB -> KEY_TAB
            KeyEvent.KEYCODE_ESCAPE -> KEY_ESC
            KeyEvent.KEYCODE_DEL -> KEY_BACKSPACE
            KeyEvent.KEYCODE_FORWARD_DEL -> KEY_DELETE
            KeyEvent.KEYCODE_SHIFT_LEFT -> KEY_LEFTSHIFT
            KeyEvent.KEYCODE_SHIFT_RIGHT -> KEY_RIGHTSHIFT
            KeyEvent.KEYCODE_CTRL_LEFT -> KEY_LEFTCTRL
            KeyEvent.KEYCODE_CTRL_RIGHT -> KEY_RIGHTCTRL
            KeyEvent.KEYCODE_ALT_LEFT -> KEY_LEFTALT
            KeyEvent.KEYCODE_ALT_RIGHT -> KEY_RIGHTALT
            KeyEvent.KEYCODE_META_LEFT -> KEY_LEFTMETA
            KeyEvent.KEYCODE_META_RIGHT -> KEY_RIGHTMETA
            KeyEvent.KEYCODE_CAPS_LOCK -> KEY_CAPSLOCK
            KeyEvent.KEYCODE_DPAD_UP -> KEY_UP
            KeyEvent.KEYCODE_DPAD_DOWN -> KEY_DOWN
            KeyEvent.KEYCODE_DPAD_LEFT -> KEY_LEFT
            KeyEvent.KEYCODE_DPAD_RIGHT -> KEY_RIGHT
            KeyEvent.KEYCODE_HOME -> KEY_HOME
            KeyEvent.KEYCODE_INSERT -> KEY_INSERT
            KeyEvent.KEYCODE_PAGE_UP -> KEY_PAGEUP
            KeyEvent.KEYCODE_PAGE_DOWN -> KEY_PAGEDOWN
            KeyEvent.KEYCODE_MOVE_END -> KEY_END
            KeyEvent.KEYCODE_F1 -> KEY_F1
            KeyEvent.KEYCODE_F2 -> KEY_F2
            KeyEvent.KEYCODE_F3 -> KEY_F3
            KeyEvent.KEYCODE_F4 -> KEY_F4
            KeyEvent.KEYCODE_F5 -> KEY_F5
            KeyEvent.KEYCODE_F6 -> KEY_F6
            KeyEvent.KEYCODE_F7 -> KEY_F7
            KeyEvent.KEYCODE_F8 -> KEY_F8
            KeyEvent.KEYCODE_F9 -> KEY_F9
            KeyEvent.KEYCODE_F10 -> KEY_F10
            KeyEvent.KEYCODE_F11 -> KEY_F11
            KeyEvent.KEYCODE_F12 -> KEY_F12
            KeyEvent.KEYCODE_MINUS -> KEY_MINUS
            KeyEvent.KEYCODE_EQUALS -> KEY_EQUAL
            KeyEvent.KEYCODE_LEFT_BRACKET -> KEY_LEFTBRACE
            KeyEvent.KEYCODE_RIGHT_BRACKET -> KEY_RIGHTBRACE
            KeyEvent.KEYCODE_BACKSLASH -> KEY_BACKSLASH
            KeyEvent.KEYCODE_SEMICOLON -> KEY_SEMICOLON
            KeyEvent.KEYCODE_APOSTROPHE -> KEY_APOSTROPHE
            KeyEvent.KEYCODE_GRAVE -> KEY_GRAVE
            KeyEvent.KEYCODE_COMMA -> KEY_COMMA
            KeyEvent.KEYCODE_PERIOD -> KEY_DOT
            KeyEvent.KEYCODE_SLASH -> KEY_SLASH
            else -> 0
        }
    }

    /**
     * Convert character to Linux keycode and shift state.
     */
    private fun charToLinuxKeyCode(char: Char): Pair<Int, Boolean>? {
        return when (char) {
            in 'a'..'z' -> Pair(KEY_A + (char - 'a'), false)
            in 'A'..'Z' -> Pair(KEY_A + (char - 'A'), true)
            in '0'..'9' -> Pair(KEY_1 + (char - '1'), false).let {
                if (char == '0') Pair(KEY_0, false) else it
            }
            ' ' -> Pair(KEY_SPACE, false)
            '\n' -> Pair(KEY_ENTER, false)
            '\t' -> Pair(KEY_TAB, false)
            '!' -> Pair(KEY_1, true)
            '@' -> Pair(KEY_2, true)
            '#' -> Pair(KEY_3, true)
            '$' -> Pair(KEY_4, true)
            '%' -> Pair(KEY_5, true)
            '^' -> Pair(KEY_6, true)
            '&' -> Pair(KEY_7, true)
            '*' -> Pair(KEY_8, true)
            '(' -> Pair(KEY_9, true)
            ')' -> Pair(KEY_0, true)
            '-' -> Pair(KEY_MINUS, false)
            '_' -> Pair(KEY_MINUS, true)
            '=' -> Pair(KEY_EQUAL, false)
            '+' -> Pair(KEY_EQUAL, true)
            '[' -> Pair(KEY_LEFTBRACE, false)
            '{' -> Pair(KEY_LEFTBRACE, true)
            ']' -> Pair(KEY_RIGHTBRACE, false)
            '}' -> Pair(KEY_RIGHTBRACE, true)
            '\\' -> Pair(KEY_BACKSLASH, false)
            '|' -> Pair(KEY_BACKSLASH, true)
            ';' -> Pair(KEY_SEMICOLON, false)
            ':' -> Pair(KEY_SEMICOLON, true)
            '\'' -> Pair(KEY_APOSTROPHE, false)
            '"' -> Pair(KEY_APOSTROPHE, true)
            ',' -> Pair(KEY_COMMA, false)
            '<' -> Pair(KEY_COMMA, true)
            '.' -> Pair(KEY_DOT, false)
            '>' -> Pair(KEY_DOT, true)
            '/' -> Pair(KEY_SLASH, false)
            '?' -> Pair(KEY_SLASH, true)
            '`' -> Pair(KEY_GRAVE, false)
            '~' -> Pair(KEY_GRAVE, true)
            else -> null
        }
    }
}
