package app.gsmlg.emulate_keyboard

import android.content.Context
import android.os.Build
import android.util.Log
import android.view.KeyEvent

/**
 * VirtualDeviceManager backend for keyboard emulation.
 *
 * Uses Android's VirtualDeviceManager API (Android 14+) to create
 * a virtual input device that appears as a real hardware keyboard.
 *
 * Requirements:
 * - Android 14 (API 34) or higher
 * - CREATE_VIRTUAL_DEVICE permission (system/privileged app)
 */
class VirtualDeviceBackend(private val context: Context) : IKeyboardBackend {

    companion object {
        private const val TAG = "VirtualDeviceBackend"
        private const val VIRTUAL_DEVICE_NAME = "TeleDeck Virtual Keyboard"
        private const val VENDOR_ID = 0x1234
        private const val PRODUCT_ID = 0x5678
    }

    // VirtualDevice API objects (stored as Any to avoid compile-time dependency)
    private var virtualDeviceManager: Any? = null
    private var virtualDevice: Any? = null
    private var virtualKeyboard: Any? = null

    override var isAvailable: Boolean = false
        private set

    override var isInitialized: Boolean = false
        private set

    override val isConnected: Boolean
        get() = virtualKeyboard != null

    private var statusMessage: String = ""
    private var errorMessage: String? = null

    init {
        checkAvailability()
    }

    private fun checkAvailability() {
        // VirtualKeyboard input APIs require API 34 (Android 14)
        if (Build.VERSION.SDK_INT < 34) {
            statusMessage = "Requires Android 14+ (API 34)"
            isAvailable = false
            return
        }

        try {
            // Try to get VirtualDeviceManager service
            val vdmClass = Class.forName("android.companion.virtual.VirtualDeviceManager")
            val vdm = context.getSystemService(vdmClass)

            if (vdm == null) {
                statusMessage = "VirtualDeviceManager service not available"
                isAvailable = false
                return
            }

            virtualDeviceManager = vdm
            statusMessage = "Available (Android 14+)"
            isAvailable = true
            Log.d(TAG, "VirtualDeviceManager service found")

        } catch (e: ClassNotFoundException) {
            statusMessage = "VirtualDeviceManager not found in SDK"
            isAvailable = false
        } catch (e: Exception) {
            statusMessage = "Failed to get VirtualDeviceManager: ${e.message}"
            errorMessage = e.message
            isAvailable = false
        }
    }

    override fun initialize(): Boolean {
        if (!isAvailable) {
            Log.w(TAG, "VirtualDeviceManager not available")
            return false
        }

        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        return initializeViaReflection()
    }

    private fun initializeViaReflection(): Boolean {
        try {
            val vdm = virtualDeviceManager ?: return false

            Log.d(TAG, "Creating VirtualDevice")

            // Get VirtualDeviceParams.Builder
            val paramsBuilderClass = Class.forName("android.companion.virtual.VirtualDeviceParams\$Builder")
            val paramsBuilder = paramsBuilderClass.getDeclaredConstructor().newInstance()

            // Set name
            paramsBuilderClass.getMethod("setName", String::class.java)
                .invoke(paramsBuilder, VIRTUAL_DEVICE_NAME)

            // Build params
            val params = paramsBuilderClass.getMethod("build").invoke(paramsBuilder)

            // Create virtual device
            val vdmClass = Class.forName("android.companion.virtual.VirtualDeviceManager")
            val createMethod = vdmClass.getMethod(
                "createVirtualDevice",
                Int::class.javaPrimitiveType,
                Class.forName("android.companion.virtual.VirtualDeviceParams")
            )

            // Note: associationId=0 requires CREATE_VIRTUAL_DEVICE permission
            val device = createMethod.invoke(vdm, 0, params)

            if (device == null) {
                errorMessage = "Failed to create VirtualDevice"
                return false
            }

            virtualDevice = device
            Log.d(TAG, "VirtualDevice created successfully")

            // Create VirtualKeyboardConfig
            val keyboardConfigBuilderClass = Class.forName(
                "android.companion.virtual.input.VirtualKeyboardConfig\$Builder"
            )
            val keyboardConfigBuilder = keyboardConfigBuilderClass.getDeclaredConstructor().newInstance()

            keyboardConfigBuilderClass.getMethod("setVendorId", Int::class.javaPrimitiveType)
                .invoke(keyboardConfigBuilder, VENDOR_ID)
            keyboardConfigBuilderClass.getMethod("setProductId", Int::class.javaPrimitiveType)
                .invoke(keyboardConfigBuilder, PRODUCT_ID)
            keyboardConfigBuilderClass.getMethod("setInputDeviceName", String::class.java)
                .invoke(keyboardConfigBuilder, VIRTUAL_DEVICE_NAME)

            val keyboardConfig = keyboardConfigBuilderClass.getMethod("build").invoke(keyboardConfigBuilder)

            // Create virtual keyboard
            val deviceClass = Class.forName("android.companion.virtual.VirtualDevice")
            val createKeyboardMethod = deviceClass.getMethod(
                "createVirtualKeyboard",
                Class.forName("android.companion.virtual.input.VirtualKeyboardConfig")
            )
            val keyboard = createKeyboardMethod.invoke(device, keyboardConfig)

            if (keyboard == null) {
                errorMessage = "Failed to create VirtualKeyboard"
                cleanup()
                return false
            }

            virtualKeyboard = keyboard
            isInitialized = true
            statusMessage = "Initialized and ready"
            Log.d(TAG, "VirtualKeyboard created successfully")
            return true

        } catch (e: SecurityException) {
            errorMessage = "Permission denied: CREATE_VIRTUAL_DEVICE required"
            Log.e(TAG, "Permission denied", e)
            isAvailable = false
            return false
        } catch (e: ClassNotFoundException) {
            errorMessage = "VirtualDevice classes not found in SDK"
            Log.e(TAG, "Classes not found", e)
            isAvailable = false
            return false
        } catch (e: Exception) {
            errorMessage = "Failed to initialize: ${e.message}"
            Log.e(TAG, "Failed to initialize VirtualDevice", e)
            cleanup()
            return false
        }
    }

    override fun cleanup() {
        Log.d(TAG, "Cleaning up VirtualDevice")

        try {
            virtualKeyboard?.let { keyboard ->
                keyboard.javaClass.getMethod("close").invoke(keyboard)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VirtualKeyboard", e)
        }
        virtualKeyboard = null

        try {
            virtualDevice?.let { device ->
                device.javaClass.getMethod("close").invoke(device)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VirtualDevice", e)
        }
        virtualDevice = null

        isInitialized = false
        statusMessage = if (isAvailable) "Available (Android 14+)" else statusMessage
    }

    override fun getStatus(): Map<String, Any?> {
        return mapOf(
            "backend" to "virtualDevice",
            "isAvailable" to isAvailable,
            "isInitialized" to isInitialized,
            "isConnected" to isConnected,
            "message" to statusMessage,
            "error" to errorMessage,
            "details" to mapOf(
                "apiLevel" to Build.VERSION.SDK_INT,
                "requiredApiLevel" to 34
            )
        )
    }

    override fun sendKeyEvent(
        keyCode: Int,
        shift: Boolean,
        ctrl: Boolean,
        alt: Boolean,
        meta: Boolean,
        isDown: Boolean?
    ): Boolean {
        if (virtualKeyboard == null) {
            Log.w(TAG, "VirtualKeyboard not initialized")
            return false
        }

        return try {
            when (isDown) {
                true -> sendSingleKeyEvent(keyCode, true)
                false -> sendSingleKeyEvent(keyCode, false)
                null -> {
                    // Full key press: modifiers down, key down, key up, modifiers up
                    if (shift) sendSingleKeyEvent(KeyEvent.KEYCODE_SHIFT_LEFT, true)
                    if (ctrl) sendSingleKeyEvent(KeyEvent.KEYCODE_CTRL_LEFT, true)
                    if (alt) sendSingleKeyEvent(KeyEvent.KEYCODE_ALT_LEFT, true)
                    if (meta) sendSingleKeyEvent(KeyEvent.KEYCODE_META_LEFT, true)

                    sendSingleKeyEvent(keyCode, true)
                    sendSingleKeyEvent(keyCode, false)

                    if (meta) sendSingleKeyEvent(KeyEvent.KEYCODE_META_LEFT, false)
                    if (alt) sendSingleKeyEvent(KeyEvent.KEYCODE_ALT_LEFT, false)
                    if (ctrl) sendSingleKeyEvent(KeyEvent.KEYCODE_CTRL_LEFT, false)
                    if (shift) sendSingleKeyEvent(KeyEvent.KEYCODE_SHIFT_LEFT, false)
                }
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send key event", e)
            false
        }
    }

    private fun sendSingleKeyEvent(keyCode: Int, isDown: Boolean) {
        val keyboard = virtualKeyboard ?: return
        val eventTime = System.currentTimeMillis()

        val keyEventBuilderClass = Class.forName(
            "android.companion.virtual.input.VirtualKeyEvent\$Builder"
        )
        val keyEventClass = Class.forName("android.companion.virtual.input.VirtualKeyEvent")
        val keyboardClass = Class.forName("android.companion.virtual.input.VirtualKeyboard")

        val actionField = keyEventClass.getField(if (isDown) "ACTION_DOWN" else "ACTION_UP")
        val action = actionField.getInt(null)

        val builder = keyEventBuilderClass.getDeclaredConstructor().newInstance()
        keyEventBuilderClass.getMethod("setKeyCode", Int::class.javaPrimitiveType)
            .invoke(builder, keyCode)
        keyEventBuilderClass.getMethod("setAction", Int::class.javaPrimitiveType)
            .invoke(builder, action)
        keyEventBuilderClass.getMethod("setEventTimeNanos", Long::class.javaPrimitiveType)
            .invoke(builder, eventTime * 1_000_000)

        val event = keyEventBuilderClass.getMethod("build").invoke(builder)

        keyboardClass.getMethod("sendKeyEvent", keyEventClass).invoke(keyboard, event)
    }

    override fun typeText(text: String): Boolean {
        if (virtualKeyboard == null) return false

        for (char in text) {
            val keyInfo = charToKeyCode(char)
            if (keyInfo != null) {
                sendKeyEvent(keyInfo.first, keyInfo.second, ctrl = false, alt = false, meta = false, isDown = null)
                // Small delay between characters
                Thread.sleep(10)
            }
        }
        return true
    }

    /**
     * Convert a character to its keycode and shift state.
     * Returns Pair(keyCode, needsShift)
     */
    private fun charToKeyCode(char: Char): Pair<Int, Boolean>? {
        return when (char) {
            in 'a'..'z' -> Pair(KeyEvent.KEYCODE_A + (char - 'a'), false)
            in 'A'..'Z' -> Pair(KeyEvent.KEYCODE_A + (char - 'A'), true)
            in '0'..'9' -> Pair(KeyEvent.KEYCODE_0 + (char - '0'), false)
            ' ' -> Pair(KeyEvent.KEYCODE_SPACE, false)
            '\n' -> Pair(KeyEvent.KEYCODE_ENTER, false)
            '\t' -> Pair(KeyEvent.KEYCODE_TAB, false)
            '!' -> Pair(KeyEvent.KEYCODE_1, true)
            '@' -> Pair(KeyEvent.KEYCODE_2, true)
            '#' -> Pair(KeyEvent.KEYCODE_3, true)
            '$' -> Pair(KeyEvent.KEYCODE_4, true)
            '%' -> Pair(KeyEvent.KEYCODE_5, true)
            '^' -> Pair(KeyEvent.KEYCODE_6, true)
            '&' -> Pair(KeyEvent.KEYCODE_7, true)
            '*' -> Pair(KeyEvent.KEYCODE_8, true)
            '(' -> Pair(KeyEvent.KEYCODE_9, true)
            ')' -> Pair(KeyEvent.KEYCODE_0, true)
            '-' -> Pair(KeyEvent.KEYCODE_MINUS, false)
            '_' -> Pair(KeyEvent.KEYCODE_MINUS, true)
            '=' -> Pair(KeyEvent.KEYCODE_EQUALS, false)
            '+' -> Pair(KeyEvent.KEYCODE_EQUALS, true)
            '[' -> Pair(KeyEvent.KEYCODE_LEFT_BRACKET, false)
            '{' -> Pair(KeyEvent.KEYCODE_LEFT_BRACKET, true)
            ']' -> Pair(KeyEvent.KEYCODE_RIGHT_BRACKET, false)
            '}' -> Pair(KeyEvent.KEYCODE_RIGHT_BRACKET, true)
            '\\' -> Pair(KeyEvent.KEYCODE_BACKSLASH, false)
            '|' -> Pair(KeyEvent.KEYCODE_BACKSLASH, true)
            ';' -> Pair(KeyEvent.KEYCODE_SEMICOLON, false)
            ':' -> Pair(KeyEvent.KEYCODE_SEMICOLON, true)
            '\'' -> Pair(KeyEvent.KEYCODE_APOSTROPHE, false)
            '"' -> Pair(KeyEvent.KEYCODE_APOSTROPHE, true)
            ',' -> Pair(KeyEvent.KEYCODE_COMMA, false)
            '<' -> Pair(KeyEvent.KEYCODE_COMMA, true)
            '.' -> Pair(KeyEvent.KEYCODE_PERIOD, false)
            '>' -> Pair(KeyEvent.KEYCODE_PERIOD, true)
            '/' -> Pair(KeyEvent.KEYCODE_SLASH, false)
            '?' -> Pair(KeyEvent.KEYCODE_SLASH, true)
            '`' -> Pair(KeyEvent.KEYCODE_GRAVE, false)
            '~' -> Pair(KeyEvent.KEYCODE_GRAVE, true)
            else -> null
        }
    }
}
