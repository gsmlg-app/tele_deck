package app.gsmlg.tele_deck

import android.content.Context
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.KeyEvent

/**
 * Manages virtual keyboard emulation for physical keyboard mode.
 *
 * This class attempts to use Android's VirtualDeviceManager API (Android 14+) to create
 * a virtual input device that appears as a real hardware keyboard to apps.
 *
 * IMPORTANT LIMITATIONS:
 * - VirtualDeviceManager requires android.permission.CREATE_VIRTUAL_DEVICE (signature|privileged)
 * - VirtualDevice creation requires CompanionDeviceManager association (user approval flow)
 * - Without system-level privileges, this will gracefully fall back to InputConnection
 *
 * Fallback behavior:
 * When VirtualKeyboard is unavailable, the IME service uses InputConnection.sendKeyEvent()
 * which sends key events through the IME framework. This works for most apps but may not
 * work with games that expect raw hardware keyboard events.
 *
 * Requirements for full physical keyboard emulation:
 * - Android 14+ (API 34)
 * - App signed with platform key OR
 * - App installed as privileged system app OR
 * - CompanionDeviceManager setup (complex, requires user approval)
 */
class VirtualKeyboardManager(private val context: Context) {

    companion object {
        private const val TAG = "VirtualKeyboardMgr"
        private const val VIRTUAL_DEVICE_NAME = "TeleDeck Virtual Device"
        private const val VIRTUAL_KEYBOARD_NAME = "TeleDeck Virtual Keyboard"

        // Vendor and Product IDs for the virtual keyboard
        private const val VENDOR_ID = 0x1234
        private const val PRODUCT_ID = 0x5678
    }

    // VirtualDevice API types stored as Any to avoid compile-time dependency
    private var virtualDeviceManager: Any? = null
    private var virtualDevice: Any? = null
    private var virtualKeyboard: Any? = null

    // Track if VirtualDeviceManager is available and permission granted
    var isAvailable: Boolean = false
        private set

    init {
        checkAvailability()
    }

    /**
     * Check if VirtualDeviceManager is available on this device.
     * This checks both API level and permission availability.
     */
    private fun checkAvailability() {
        // VirtualKeyboard input APIs require API 34 (Android 14)
        if (Build.VERSION.SDK_INT < 34) {
            Log.d(TAG, "VirtualDeviceManager not available - requires Android 14+ (API 34)")
            isAvailable = false
            return
        }

        try {
            // Try to get VirtualDeviceManager service
            val vdmClass = Class.forName("android.companion.virtual.VirtualDeviceManager")
            val vdm = context.getSystemService(vdmClass)

            if (vdm == null) {
                Log.d(TAG, "VirtualDeviceManager service not available")
                isAvailable = false
                return
            }

            virtualDeviceManager = vdm

            // The service exists, but we still need to test if we can create virtual devices
            // This will fail if we don't have the CREATE_VIRTUAL_DEVICE permission
            // We'll defer the actual check to initialize() to avoid startup delays
            isAvailable = true
            Log.d(TAG, "VirtualDeviceManager service found - will test device creation on initialize()")

        } catch (e: ClassNotFoundException) {
            Log.d(TAG, "VirtualDeviceManager class not found in SDK")
            isAvailable = false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get VirtualDeviceManager", e)
            isAvailable = false
        }
    }

    /**
     * Initialize the virtual device and keyboard.
     * Must be called before sending key events in physical mode.
     *
     * @param targetDisplay The display to associate the virtual device with
     * @return true if initialization succeeded
     */
    fun initialize(targetDisplay: Display?): Boolean {
        if (!isAvailable) {
            Log.w(TAG, "VirtualDeviceManager not available")
            return false
        }

        if (virtualDevice != null && virtualKeyboard != null) {
            Log.d(TAG, "Virtual device already initialized")
            return true
        }

        if (Build.VERSION.SDK_INT < 34) {
            return false
        }

        return initializeViaReflection(targetDisplay)
    }

    /**
     * Initialize VirtualDevice using reflection to avoid compile-time dependencies.
     * This allows the code to compile even if the SDK doesn't include these classes.
     */
    private fun initializeViaReflection(targetDisplay: Display?): Boolean {
        try {
            val vdm = virtualDeviceManager ?: return false
            val displayId = targetDisplay?.displayId ?: Display.DEFAULT_DISPLAY
            Log.d(TAG, "Creating VirtualDevice for display: $displayId")

            // Get VirtualDeviceParams.Builder
            val paramsBuilderClass = Class.forName("android.companion.virtual.VirtualDeviceParams\$Builder")
            val paramsBuilder = paramsBuilderClass.getDeclaredConstructor().newInstance()

            // Set name
            val setNameMethod = paramsBuilderClass.getMethod("setName", String::class.java)
            setNameMethod.invoke(paramsBuilder, VIRTUAL_DEVICE_NAME)

            // Build params
            val buildMethod = paramsBuilderClass.getMethod("build")
            val params = buildMethod.invoke(paramsBuilder)

            // Create virtual device
            val vdmClass = Class.forName("android.companion.virtual.VirtualDeviceManager")
            val createMethod = vdmClass.getMethod(
                "createVirtualDevice",
                Int::class.javaPrimitiveType,
                Class.forName("android.companion.virtual.VirtualDeviceParams")
            )

            // Note: associationId=0 requires CREATE_VIRTUAL_DEVICE permission
            // Without proper permission, this will throw SecurityException
            val device = createMethod.invoke(vdm, 0, params)

            if (device == null) {
                Log.e(TAG, "Failed to create VirtualDevice")
                return false
            }

            virtualDevice = device
            Log.d(TAG, "VirtualDevice created successfully")

            // Create VirtualKeyboardConfig
            val keyboardConfigBuilderClass = Class.forName("android.companion.virtual.input.VirtualKeyboardConfig\$Builder")
            val keyboardConfigBuilder = keyboardConfigBuilderClass.getDeclaredConstructor().newInstance()

            // Set vendor ID, product ID, and name
            keyboardConfigBuilderClass.getMethod("setVendorId", Int::class.javaPrimitiveType)
                .invoke(keyboardConfigBuilder, VENDOR_ID)
            keyboardConfigBuilderClass.getMethod("setProductId", Int::class.javaPrimitiveType)
                .invoke(keyboardConfigBuilder, PRODUCT_ID)
            keyboardConfigBuilderClass.getMethod("setInputDeviceName", String::class.java)
                .invoke(keyboardConfigBuilder, VIRTUAL_KEYBOARD_NAME)

            val keyboardConfig = keyboardConfigBuilderClass.getMethod("build").invoke(keyboardConfigBuilder)

            // Create virtual keyboard
            val deviceClass = Class.forName("android.companion.virtual.VirtualDevice")
            val createKeyboardMethod = deviceClass.getMethod(
                "createVirtualKeyboard",
                Class.forName("android.companion.virtual.input.VirtualKeyboardConfig")
            )
            val keyboard = createKeyboardMethod.invoke(device, keyboardConfig)

            if (keyboard == null) {
                Log.e(TAG, "Failed to create VirtualKeyboard")
                cleanup()
                return false
            }

            virtualKeyboard = keyboard
            Log.d(TAG, "VirtualKeyboard created successfully")
            return true

        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied for CREATE_VIRTUAL_DEVICE - falling back to InputConnection", e)
            isAvailable = false
            return false
        } catch (e: ClassNotFoundException) {
            Log.e(TAG, "VirtualDevice classes not found in SDK", e)
            isAvailable = false
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize VirtualDevice via reflection", e)
            cleanup()
            return false
        }
    }

    /**
     * Send a key event through the virtual keyboard.
     * The event appears as if from a physical hardware keyboard.
     *
     * @param keyCode Android KeyEvent key code (e.g., KeyEvent.KEYCODE_A)
     * @param metaState Modifier key state (e.g., KeyEvent.META_SHIFT_ON)
     */
    fun sendKeyEvent(keyCode: Int, metaState: Int = 0) {
        if (virtualKeyboard == null) {
            Log.w(TAG, "VirtualKeyboard not initialized")
            return
        }

        if (Build.VERSION.SDK_INT < 34) {
            return
        }

        sendKeyEventViaReflection(keyCode, metaState)
    }

    private fun sendKeyEventViaReflection(keyCode: Int, metaState: Int) {
        try {
            val keyboard = virtualKeyboard ?: return
            val eventTime = System.currentTimeMillis()

            // Get VirtualKeyEvent classes
            val keyEventBuilderClass = Class.forName("android.companion.virtual.input.VirtualKeyEvent\$Builder")
            val keyEventClass = Class.forName("android.companion.virtual.input.VirtualKeyEvent")
            val keyboardClass = Class.forName("android.companion.virtual.input.VirtualKeyboard")

            val actionDownField = keyEventClass.getField("ACTION_DOWN")
            val actionUpField = keyEventClass.getField("ACTION_UP")
            val actionDown = actionDownField.getInt(null)
            val actionUp = actionUpField.getInt(null)

            // Send KEY_DOWN event
            val downBuilder = keyEventBuilderClass.getDeclaredConstructor().newInstance()
            keyEventBuilderClass.getMethod("setKeyCode", Int::class.javaPrimitiveType)
                .invoke(downBuilder, keyCode)
            keyEventBuilderClass.getMethod("setAction", Int::class.javaPrimitiveType)
                .invoke(downBuilder, actionDown)
            keyEventBuilderClass.getMethod("setEventTimeNanos", Long::class.javaPrimitiveType)
                .invoke(downBuilder, eventTime * 1_000_000)
            val downEvent = keyEventBuilderClass.getMethod("build").invoke(downBuilder)

            val sendKeyEventMethod = keyboardClass.getMethod("sendKeyEvent", keyEventClass)
            sendKeyEventMethod.invoke(keyboard, downEvent)

            // Send KEY_UP event
            val upBuilder = keyEventBuilderClass.getDeclaredConstructor().newInstance()
            keyEventBuilderClass.getMethod("setKeyCode", Int::class.javaPrimitiveType)
                .invoke(upBuilder, keyCode)
            keyEventBuilderClass.getMethod("setAction", Int::class.javaPrimitiveType)
                .invoke(upBuilder, actionUp)
            keyEventBuilderClass.getMethod("setEventTimeNanos", Long::class.javaPrimitiveType)
                .invoke(upBuilder, (eventTime + 50) * 1_000_000)
            val upEvent = keyEventBuilderClass.getMethod("build").invoke(upBuilder)

            sendKeyEventMethod.invoke(keyboard, upEvent)

            Log.d(TAG, "Sent key event: keyCode=$keyCode, metaState=$metaState")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to send key event via reflection", e)
        }
    }

    /**
     * Send a key event with modifier keys.
     * Handles pressing and releasing modifier keys around the main key.
     */
    fun sendKeyEventWithModifiers(
        keyCode: Int,
        shift: Boolean = false,
        ctrl: Boolean = false,
        alt: Boolean = false,
        meta: Boolean = false
    ) {
        if (virtualKeyboard == null) {
            Log.w(TAG, "VirtualKeyboard not initialized")
            return
        }

        if (Build.VERSION.SDK_INT < 34) {
            return
        }

        try {
            // Press modifier keys
            if (shift) sendSingleKeyEvent(KeyEvent.KEYCODE_SHIFT_LEFT, true)
            if (ctrl) sendSingleKeyEvent(KeyEvent.KEYCODE_CTRL_LEFT, true)
            if (alt) sendSingleKeyEvent(KeyEvent.KEYCODE_ALT_LEFT, true)
            if (meta) sendSingleKeyEvent(KeyEvent.KEYCODE_META_LEFT, true)

            // Send the main key
            sendSingleKeyEvent(keyCode, true)
            sendSingleKeyEvent(keyCode, false)

            // Release modifier keys (reverse order)
            if (meta) sendSingleKeyEvent(KeyEvent.KEYCODE_META_LEFT, false)
            if (alt) sendSingleKeyEvent(KeyEvent.KEYCODE_ALT_LEFT, false)
            if (ctrl) sendSingleKeyEvent(KeyEvent.KEYCODE_CTRL_LEFT, false)
            if (shift) sendSingleKeyEvent(KeyEvent.KEYCODE_SHIFT_LEFT, false)

            Log.d(TAG, "Sent key with modifiers: keyCode=$keyCode, shift=$shift, ctrl=$ctrl, alt=$alt, meta=$meta")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to send key event with modifiers", e)
        }
    }

    private fun sendSingleKeyEvent(keyCode: Int, isDown: Boolean) {
        try {
            val keyboard = virtualKeyboard ?: return
            val eventTime = System.currentTimeMillis()

            val keyEventBuilderClass = Class.forName("android.companion.virtual.input.VirtualKeyEvent\$Builder")
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

            val sendKeyEventMethod = keyboardClass.getMethod("sendKeyEvent", keyEventClass)
            sendKeyEventMethod.invoke(keyboard, event)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to send single key event", e)
        }
    }

    /**
     * Clean up the virtual device and keyboard.
     */
    fun cleanup() {
        Log.d(TAG, "Cleaning up VirtualDevice and VirtualKeyboard")

        try {
            virtualKeyboard?.let { keyboard ->
                val closeMethod = keyboard.javaClass.getMethod("close")
                closeMethod.invoke(keyboard)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VirtualKeyboard", e)
        }
        virtualKeyboard = null

        try {
            virtualDevice?.let { device ->
                val closeMethod = device.javaClass.getMethod("close")
                closeMethod.invoke(device)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VirtualDevice", e)
        }
        virtualDevice = null
    }
}
