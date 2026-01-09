package app.gsmlg.emulate_keyboard

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.view.KeyEvent
import androidx.core.content.ContextCompat

/**
 * Bluetooth HID backend for keyboard emulation.
 *
 * Uses Android's BluetoothHidDevice API to register as a HID peripheral
 * (keyboard) and send key events over Bluetooth.
 *
 * Requirements:
 * - Android 9 (API 28) or higher
 * - Bluetooth permissions
 * - Bluetooth enabled
 */
class BluetoothHidBackend(private val context: Context) : IKeyboardBackend {

    companion object {
        private const val TAG = "BluetoothHidBackend"

        // HID keyboard descriptor (standard keyboard)
        private val KEYBOARD_REPORT_DESCRIPTOR = byteArrayOf(
            0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop)
            0x09.toByte(), 0x06.toByte(), // Usage (Keyboard)
            0xA1.toByte(), 0x01.toByte(), // Collection (Application)

            // Modifier keys (8 bits)
            0x05.toByte(), 0x07.toByte(), // Usage Page (Key Codes)
            0x19.toByte(), 0xE0.toByte(), // Usage Minimum (224) - Left Ctrl
            0x29.toByte(), 0xE7.toByte(), // Usage Maximum (231) - Right Meta
            0x15.toByte(), 0x00.toByte(), // Logical Minimum (0)
            0x25.toByte(), 0x01.toByte(), // Logical Maximum (1)
            0x75.toByte(), 0x01.toByte(), // Report Size (1)
            0x95.toByte(), 0x08.toByte(), // Report Count (8)
            0x81.toByte(), 0x02.toByte(), // Input (Data, Variable, Absolute)

            // Reserved byte
            0x75.toByte(), 0x08.toByte(), // Report Size (8)
            0x95.toByte(), 0x01.toByte(), // Report Count (1)
            0x81.toByte(), 0x01.toByte(), // Input (Constant)

            // Key codes (6 keys)
            0x05.toByte(), 0x07.toByte(), // Usage Page (Key Codes)
            0x19.toByte(), 0x00.toByte(), // Usage Minimum (0)
            0x29.toByte(), 0x65.toByte(), // Usage Maximum (101)
            0x15.toByte(), 0x00.toByte(), // Logical Minimum (0)
            0x25.toByte(), 0x65.toByte(), // Logical Maximum (101)
            0x75.toByte(), 0x08.toByte(), // Report Size (8)
            0x95.toByte(), 0x06.toByte(), // Report Count (6)
            0x81.toByte(), 0x00.toByte(), // Input (Data, Array)

            0xC0.toByte()  // End Collection
        )
    }

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var hidDevice: BluetoothHidDevice? = null
    private var connectedDevice: BluetoothDevice? = null
    private var isRegistered: Boolean = false

    override var isAvailable: Boolean = false
        private set

    override var isInitialized: Boolean = false
        private set

    override val isConnected: Boolean
        get() = connectedDevice != null

    private var statusMessage: String = ""
    private var errorMessage: String? = null

    // Current keyboard state (for HID report)
    private var currentModifiers: Byte = 0
    private val pressedKeys = mutableListOf<Byte>()

    init {
        checkAvailability()
    }

    private fun checkAvailability() {
        // BluetoothHidDevice API requires API 28+
        if (Build.VERSION.SDK_INT < 28) {
            statusMessage = "Requires Android 9+ (API 28)"
            isAvailable = false
            return
        }

        // Check Bluetooth availability
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null) {
            statusMessage = "Bluetooth not available"
            isAvailable = false
            return
        }

        statusMessage = "Available (requires Bluetooth)"
        isAvailable = true
    }

    override fun initialize(): Boolean {
        if (!isAvailable) {
            Log.w(TAG, "Bluetooth HID not available")
            return false
        }

        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        // Check permissions
        if (!checkPermissions()) {
            errorMessage = "Bluetooth permissions not granted"
            return false
        }

        // Check if Bluetooth is enabled
        if (bluetoothAdapter?.isEnabled != true) {
            errorMessage = "Bluetooth is disabled"
            return false
        }

        // Get HID profile proxy
        return try {
            val result = bluetoothAdapter?.getProfileProxy(
                context,
                profileListener,
                BluetoothProfile.HID_DEVICE
            )
            if (result == true) {
                statusMessage = "Initializing HID device..."
                Log.d(TAG, "Requested HID profile proxy")
                // Will complete in profileListener.onServiceConnected
                true
            } else {
                errorMessage = "Failed to get HID profile"
                false
            }
        } catch (e: SecurityException) {
            errorMessage = "Bluetooth permission denied"
            Log.e(TAG, "Permission denied", e)
            false
        } catch (e: Exception) {
            errorMessage = "Failed to initialize: ${e.message}"
            Log.e(TAG, "Failed to initialize", e)
            false
        }
    }

    private val profileListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hidDevice = proxy as BluetoothHidDevice
                Log.d(TAG, "HID Device service connected")
                registerHidDevice()
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hidDevice = null
                isRegistered = false
                isInitialized = false
                statusMessage = "HID service disconnected"
                Log.d(TAG, "HID Device service disconnected")
            }
        }
    }

    @Suppress("MissingPermission")
    private fun registerHidDevice() {
        val hid = hidDevice ?: return

        val sdpSettings = BluetoothHidDeviceAppSdpSettings(
            "TeleDeck Keyboard",
            "Virtual Keyboard",
            "TeleDeck",
            BluetoothHidDevice.SUBCLASS1_KEYBOARD,
            KEYBOARD_REPORT_DESCRIPTOR
        )

        try {
            val registered = hid.registerApp(
                sdpSettings,
                null, // No QoS settings
                null, // No report callback
                { it.run() }, // Executor
                hidCallback
            )

            if (registered) {
                isRegistered = true
                isInitialized = true
                statusMessage = "HID keyboard registered"
                Log.d(TAG, "HID device registered successfully")
            } else {
                errorMessage = "Failed to register HID app"
                Log.e(TAG, "Failed to register HID app")
            }
        } catch (e: SecurityException) {
            errorMessage = "Permission denied during registration"
            Log.e(TAG, "Permission denied", e)
        } catch (e: Exception) {
            errorMessage = "Registration failed: ${e.message}"
            Log.e(TAG, "Registration failed", e)
        }
    }

    private val hidCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            Log.d(TAG, "App status changed: registered=$registered")
            isRegistered = registered
            if (registered) {
                statusMessage = "HID keyboard ready"
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            Log.d(TAG, "Connection state changed: state=$state")
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    statusMessage = "Connected to ${device?.name ?: "device"}"
                    Log.d(TAG, "Connected to ${device?.name}")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    connectedDevice = null
                    statusMessage = "Disconnected"
                    Log.d(TAG, "Disconnected")
                }
            }
        }
    }

    override fun cleanup() {
        Log.d(TAG, "Cleaning up Bluetooth HID")

        try {
            hidDevice?.let { hid ->
                @Suppress("MissingPermission")
                hid.unregisterApp()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering HID app", e)
        }

        try {
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, hidDevice)
        } catch (e: Exception) {
            Log.w(TAG, "Error closing profile proxy", e)
        }

        hidDevice = null
        connectedDevice = null
        isRegistered = false
        isInitialized = false
        statusMessage = "Available (requires Bluetooth)"
    }

    override fun getStatus(): Map<String, Any?> {
        return mapOf(
            "backend" to "bluetoothHid",
            "isAvailable" to isAvailable,
            "isInitialized" to isInitialized,
            "isConnected" to isConnected,
            "message" to statusMessage,
            "error" to errorMessage,
            "details" to mapOf(
                "isBluetoothEnabled" to (bluetoothAdapter?.isEnabled == true),
                "isRegistered" to isRegistered,
                "connectedDevice" to connectedDevice?.name
            )
        )
    }

    private fun checkPermissions(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= 31) {
            listOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_ADVERTISE
            )
        } else {
            listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN
            )
        }

        return permissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Start advertising as a Bluetooth keyboard.
     */
    fun startAdvertising(): Boolean {
        // Advertising happens automatically when registered as HID device
        // The device becomes discoverable when Bluetooth is in discoverable mode
        return isRegistered
    }

    /**
     * Stop advertising.
     */
    fun stopAdvertising(): Boolean {
        return true // No explicit stop needed
    }

    /**
     * Get list of paired devices.
     */
    @Suppress("MissingPermission")
    fun getPairedDevices(): List<Map<String, String>> {
        return try {
            bluetoothAdapter?.bondedDevices?.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address
                )
            } ?: emptyList()
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied getting paired devices", e)
            emptyList()
        }
    }

    /**
     * Connect to a specific device.
     */
    @Suppress("MissingPermission")
    fun connectToDevice(macAddress: String): Boolean {
        val hid = hidDevice ?: return false

        return try {
            val device = bluetoothAdapter?.getRemoteDevice(macAddress) ?: return false
            hid.connect(device)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect", e)
            false
        }
    }

    /**
     * Disconnect from current device.
     */
    @Suppress("MissingPermission")
    fun disconnect(): Boolean {
        val hid = hidDevice ?: return false
        val device = connectedDevice ?: return true

        return try {
            hid.disconnect(device)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disconnect", e)
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
        if (!isConnected) {
            Log.w(TAG, "Not connected to any device")
            return false
        }

        val hidKeyCode = androidToHidKeyCode(keyCode)
        if (hidKeyCode == 0) {
            Log.w(TAG, "Unknown key code: $keyCode")
            return false
        }

        return when (isDown) {
            true -> {
                updateModifiers(shift, ctrl, alt, meta)
                addKey(hidKeyCode.toByte())
                sendReport()
            }
            false -> {
                removeKey(hidKeyCode.toByte())
                if (!shift && !ctrl && !alt && !meta) {
                    currentModifiers = 0
                }
                sendReport()
            }
            null -> {
                // Full key press
                updateModifiers(shift, ctrl, alt, meta)
                addKey(hidKeyCode.toByte())
                sendReport()

                // Small delay
                Thread.sleep(10)

                // Key release
                removeKey(hidKeyCode.toByte())
                currentModifiers = 0
                sendReport()
            }
        }
    }

    private fun updateModifiers(shift: Boolean, ctrl: Boolean, alt: Boolean, meta: Boolean) {
        var mods: Byte = 0
        if (ctrl) mods = (mods.toInt() or 0x01).toByte()  // Left Ctrl
        if (shift) mods = (mods.toInt() or 0x02).toByte() // Left Shift
        if (alt) mods = (mods.toInt() or 0x04).toByte()   // Left Alt
        if (meta) mods = (mods.toInt() or 0x08).toByte()  // Left Meta
        currentModifiers = mods
    }

    private fun addKey(keyCode: Byte) {
        if (!pressedKeys.contains(keyCode) && pressedKeys.size < 6) {
            pressedKeys.add(keyCode)
        }
    }

    private fun removeKey(keyCode: Byte) {
        pressedKeys.remove(keyCode)
    }

    @Suppress("MissingPermission")
    private fun sendReport(): Boolean {
        val hid = hidDevice ?: return false
        val device = connectedDevice ?: return false

        // Build HID report: [modifiers, reserved, key1, key2, key3, key4, key5, key6]
        val report = ByteArray(8)
        report[0] = currentModifiers
        report[1] = 0 // Reserved

        for (i in pressedKeys.indices.take(6)) {
            report[i + 2] = pressedKeys[i]
        }

        return try {
            hid.sendReport(device, 0, report)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send report", e)
            false
        }
    }

    override fun typeText(text: String): Boolean {
        if (!isConnected) return false

        for (char in text) {
            val keyInfo = charToHidKeyCode(char)
            if (keyInfo != null) {
                sendKeyEvent(
                    keyCode = keyInfo.first,
                    shift = keyInfo.second,
                    ctrl = false,
                    alt = false,
                    meta = false,
                    isDown = null
                )
                Thread.sleep(20)
            }
        }
        return true
    }

    /**
     * Convert Android KeyEvent keycode to HID usage code.
     */
    private fun androidToHidKeyCode(androidKeyCode: Int): Int {
        return when (androidKeyCode) {
            KeyEvent.KEYCODE_A -> 0x04
            KeyEvent.KEYCODE_B -> 0x05
            KeyEvent.KEYCODE_C -> 0x06
            KeyEvent.KEYCODE_D -> 0x07
            KeyEvent.KEYCODE_E -> 0x08
            KeyEvent.KEYCODE_F -> 0x09
            KeyEvent.KEYCODE_G -> 0x0A
            KeyEvent.KEYCODE_H -> 0x0B
            KeyEvent.KEYCODE_I -> 0x0C
            KeyEvent.KEYCODE_J -> 0x0D
            KeyEvent.KEYCODE_K -> 0x0E
            KeyEvent.KEYCODE_L -> 0x0F
            KeyEvent.KEYCODE_M -> 0x10
            KeyEvent.KEYCODE_N -> 0x11
            KeyEvent.KEYCODE_O -> 0x12
            KeyEvent.KEYCODE_P -> 0x13
            KeyEvent.KEYCODE_Q -> 0x14
            KeyEvent.KEYCODE_R -> 0x15
            KeyEvent.KEYCODE_S -> 0x16
            KeyEvent.KEYCODE_T -> 0x17
            KeyEvent.KEYCODE_U -> 0x18
            KeyEvent.KEYCODE_V -> 0x19
            KeyEvent.KEYCODE_W -> 0x1A
            KeyEvent.KEYCODE_X -> 0x1B
            KeyEvent.KEYCODE_Y -> 0x1C
            KeyEvent.KEYCODE_Z -> 0x1D
            KeyEvent.KEYCODE_1 -> 0x1E
            KeyEvent.KEYCODE_2 -> 0x1F
            KeyEvent.KEYCODE_3 -> 0x20
            KeyEvent.KEYCODE_4 -> 0x21
            KeyEvent.KEYCODE_5 -> 0x22
            KeyEvent.KEYCODE_6 -> 0x23
            KeyEvent.KEYCODE_7 -> 0x24
            KeyEvent.KEYCODE_8 -> 0x25
            KeyEvent.KEYCODE_9 -> 0x26
            KeyEvent.KEYCODE_0 -> 0x27
            KeyEvent.KEYCODE_ENTER -> 0x28
            KeyEvent.KEYCODE_ESCAPE -> 0x29
            KeyEvent.KEYCODE_DEL -> 0x2A // Backspace
            KeyEvent.KEYCODE_TAB -> 0x2B
            KeyEvent.KEYCODE_SPACE -> 0x2C
            KeyEvent.KEYCODE_MINUS -> 0x2D
            KeyEvent.KEYCODE_EQUALS -> 0x2E
            KeyEvent.KEYCODE_LEFT_BRACKET -> 0x2F
            KeyEvent.KEYCODE_RIGHT_BRACKET -> 0x30
            KeyEvent.KEYCODE_BACKSLASH -> 0x31
            KeyEvent.KEYCODE_SEMICOLON -> 0x33
            KeyEvent.KEYCODE_APOSTROPHE -> 0x34
            KeyEvent.KEYCODE_GRAVE -> 0x35
            KeyEvent.KEYCODE_COMMA -> 0x36
            KeyEvent.KEYCODE_PERIOD -> 0x37
            KeyEvent.KEYCODE_SLASH -> 0x38
            KeyEvent.KEYCODE_CAPS_LOCK -> 0x39
            KeyEvent.KEYCODE_F1 -> 0x3A
            KeyEvent.KEYCODE_F2 -> 0x3B
            KeyEvent.KEYCODE_F3 -> 0x3C
            KeyEvent.KEYCODE_F4 -> 0x3D
            KeyEvent.KEYCODE_F5 -> 0x3E
            KeyEvent.KEYCODE_F6 -> 0x3F
            KeyEvent.KEYCODE_F7 -> 0x40
            KeyEvent.KEYCODE_F8 -> 0x41
            KeyEvent.KEYCODE_F9 -> 0x42
            KeyEvent.KEYCODE_F10 -> 0x43
            KeyEvent.KEYCODE_F11 -> 0x44
            KeyEvent.KEYCODE_F12 -> 0x45
            KeyEvent.KEYCODE_INSERT -> 0x49
            KeyEvent.KEYCODE_HOME -> 0x4A
            KeyEvent.KEYCODE_PAGE_UP -> 0x4B
            KeyEvent.KEYCODE_FORWARD_DEL -> 0x4C // Delete
            KeyEvent.KEYCODE_MOVE_END -> 0x4D
            KeyEvent.KEYCODE_PAGE_DOWN -> 0x4E
            KeyEvent.KEYCODE_DPAD_RIGHT -> 0x4F
            KeyEvent.KEYCODE_DPAD_LEFT -> 0x50
            KeyEvent.KEYCODE_DPAD_DOWN -> 0x51
            KeyEvent.KEYCODE_DPAD_UP -> 0x52
            else -> 0
        }
    }

    /**
     * Convert character to Android keycode and shift state.
     */
    private fun charToHidKeyCode(char: Char): Pair<Int, Boolean>? {
        return when (char) {
            in 'a'..'z' -> Pair(KeyEvent.KEYCODE_A + (char - 'a'), false)
            in 'A'..'Z' -> Pair(KeyEvent.KEYCODE_A + (char - 'A'), true)
            '0' -> Pair(KeyEvent.KEYCODE_0, false)
            in '1'..'9' -> Pair(KeyEvent.KEYCODE_1 + (char - '1'), false)
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
            else -> null
        }
    }
}
