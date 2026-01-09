package app.gsmlg.emulate_keyboard

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * EmulateKeyboardPlugin - Flutter plugin for physical keyboard emulation.
 *
 * Provides three backends:
 * - VirtualDeviceManager (Android 14+)
 * - uinput (requires root)
 * - Bluetooth HID
 */
class EmulateKeyboardPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val TAG = "EmulateKeyboardPlugin"
        private const val CHANNEL = "emulate_keyboard"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    // Backends
    private var virtualDeviceBackend: VirtualDeviceBackend? = null
    private var uinputBackend: UInputBackend? = null
    private var bluetoothHidBackend: BluetoothHidBackend? = null

    // Currently active backend
    private var activeBackend: KeyboardBackend? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = binding.applicationContext

        // Initialize backends (lazy, only check availability)
        virtualDeviceBackend = VirtualDeviceBackend(context)
        uinputBackend = UInputBackend(context)
        bluetoothHidBackend = BluetoothHidBackend(context)

        Log.d(TAG, "EmulateKeyboard plugin attached")
        Log.d(TAG, "VirtualDevice available: ${virtualDeviceBackend?.isAvailable}")
        Log.d(TAG, "uinput available: ${uinputBackend?.isAvailable}")
        Log.d(TAG, "BluetoothHID available: ${bluetoothHidBackend?.isAvailable}")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        cleanup()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "Method call: ${call.method}")

        when (call.method) {
            "getBackendStatus" -> getBackendStatus(result)
            "isBackendAvailable" -> isBackendAvailable(call, result)
            "initialize" -> initialize(call, result)
            "dispose" -> dispose(result)
            "sendKeyEvent" -> sendKeyEvent(call, result)
            "sendKeyEvents" -> sendKeyEvents(call, result)
            "typeText" -> typeText(call, result)

            // Bluetooth HID specific
            "startBluetoothAdvertising" -> startBluetoothAdvertising(result)
            "stopBluetoothAdvertising" -> stopBluetoothAdvertising(result)
            "getBluetoothDevices" -> getBluetoothDevices(result)
            "connectBluetoothDevice" -> connectBluetoothDevice(call, result)
            "disconnectBluetooth" -> disconnectBluetooth(result)

            // uinput specific
            "checkRootAccess" -> checkRootAccess(result)
            "requestRootAccess" -> requestRootAccess(result)

            else -> result.notImplemented()
        }
    }

    private fun getBackendStatus(result: Result) {
        val status = mapOf(
            "virtualDevice" to virtualDeviceBackend?.getStatus(),
            "uinput" to uinputBackend?.getStatus(),
            "bluetoothHid" to bluetoothHidBackend?.getStatus(),
            "activeBackend" to activeBackend?.name
        )
        result.success(status)
    }

    private fun isBackendAvailable(call: MethodCall, result: Result) {
        val backendName = call.argument<String>("backend")
        val backend = KeyboardBackend.fromName(backendName)

        val available = when (backend) {
            KeyboardBackend.VIRTUAL_DEVICE -> virtualDeviceBackend?.isAvailable == true
            KeyboardBackend.UINPUT -> uinputBackend?.isAvailable == true
            KeyboardBackend.BLUETOOTH_HID -> bluetoothHidBackend?.isAvailable == true
            null -> false
        }
        result.success(available)
    }

    private fun initialize(call: MethodCall, result: Result) {
        val backendName = call.argument<String>("backend")
        val backend = KeyboardBackend.fromName(backendName)

        if (backend == null) {
            result.error("INVALID_BACKEND", "Unknown backend: $backendName", null)
            return
        }

        // Cleanup previous backend if different
        if (activeBackend != null && activeBackend != backend) {
            cleanup()
        }

        val success = when (backend) {
            KeyboardBackend.VIRTUAL_DEVICE -> {
                virtualDeviceBackend?.initialize() ?: false
            }
            KeyboardBackend.UINPUT -> {
                uinputBackend?.initialize() ?: false
            }
            KeyboardBackend.BLUETOOTH_HID -> {
                bluetoothHidBackend?.initialize() ?: false
            }
        }

        if (success) {
            activeBackend = backend
            Log.d(TAG, "Backend initialized: $backend")
        } else {
            Log.e(TAG, "Failed to initialize backend: $backend")
        }

        result.success(success)
    }

    private fun dispose(result: Result) {
        cleanup()
        result.success(null)
    }

    private fun cleanup() {
        virtualDeviceBackend?.cleanup()
        uinputBackend?.cleanup()
        bluetoothHidBackend?.cleanup()
        activeBackend = null
    }

    private fun sendKeyEvent(call: MethodCall, result: Result) {
        val keyCode = call.argument<Int>("keyCode") ?: 0
        val shift = call.argument<Boolean>("shift") ?: false
        val ctrl = call.argument<Boolean>("ctrl") ?: false
        val alt = call.argument<Boolean>("alt") ?: false
        val meta = call.argument<Boolean>("meta") ?: false
        val isDown = call.argument<Boolean>("isDown")

        val success = when (activeBackend) {
            KeyboardBackend.VIRTUAL_DEVICE -> {
                virtualDeviceBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
            }
            KeyboardBackend.UINPUT -> {
                uinputBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
            }
            KeyboardBackend.BLUETOOTH_HID -> {
                bluetoothHidBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
            }
            null -> {
                Log.w(TAG, "No backend initialized")
                false
            }
        }

        result.success(success)
    }

    private fun sendKeyEvents(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val events = call.argument<List<Map<String, Any?>>>("events") ?: emptyList()

        var allSuccess = true
        for (event in events) {
            val keyCode = (event["keyCode"] as? Int) ?: 0
            val shift = (event["shift"] as? Boolean) ?: false
            val ctrl = (event["ctrl"] as? Boolean) ?: false
            val alt = (event["alt"] as? Boolean) ?: false
            val meta = (event["meta"] as? Boolean) ?: false
            val isDown = event["isDown"] as? Boolean

            val success = when (activeBackend) {
                KeyboardBackend.VIRTUAL_DEVICE -> {
                    virtualDeviceBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
                }
                KeyboardBackend.UINPUT -> {
                    uinputBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
                }
                KeyboardBackend.BLUETOOTH_HID -> {
                    bluetoothHidBackend?.sendKeyEvent(keyCode, shift, ctrl, alt, meta, isDown) ?: false
                }
                null -> false
            }

            if (!success) allSuccess = false
        }

        result.success(allSuccess)
    }

    private fun typeText(call: MethodCall, result: Result) {
        val text = call.argument<String>("text") ?: ""

        val success = when (activeBackend) {
            KeyboardBackend.VIRTUAL_DEVICE -> virtualDeviceBackend?.typeText(text) ?: false
            KeyboardBackend.UINPUT -> uinputBackend?.typeText(text) ?: false
            KeyboardBackend.BLUETOOTH_HID -> bluetoothHidBackend?.typeText(text) ?: false
            null -> false
        }

        result.success(success)
    }

    // === Bluetooth HID specific ===

    private fun startBluetoothAdvertising(result: Result) {
        val success = bluetoothHidBackend?.startAdvertising() ?: false
        result.success(success)
    }

    private fun stopBluetoothAdvertising(result: Result) {
        val success = bluetoothHidBackend?.stopAdvertising() ?: false
        result.success(success)
    }

    private fun getBluetoothDevices(result: Result) {
        val devices = bluetoothHidBackend?.getPairedDevices() ?: emptyList()
        result.success(devices)
    }

    private fun connectBluetoothDevice(call: MethodCall, result: Result) {
        val macAddress = call.argument<String>("macAddress") ?: ""
        val success = bluetoothHidBackend?.connectToDevice(macAddress) ?: false
        result.success(success)
    }

    private fun disconnectBluetooth(result: Result) {
        val success = bluetoothHidBackend?.disconnect() ?: false
        result.success(success)
    }

    // === uinput specific ===

    private fun checkRootAccess(result: Result) {
        val hasRoot = uinputBackend?.checkRootAccess() ?: false
        result.success(hasRoot)
    }

    private fun requestRootAccess(result: Result) {
        val granted = uinputBackend?.requestRootAccess() ?: false
        result.success(granted)
    }
}

/**
 * Enum for keyboard backends.
 */
enum class KeyboardBackend {
    VIRTUAL_DEVICE,
    UINPUT,
    BLUETOOTH_HID;

    val displayName: String
        get() = when (this) {
            VIRTUAL_DEVICE -> "virtualDevice"
            UINPUT -> "uinput"
            BLUETOOTH_HID -> "bluetoothHid"
        }

    companion object {
        fun fromName(name: String?): KeyboardBackend? {
            return when (name) {
                "virtualDevice" -> VIRTUAL_DEVICE
                "uinput" -> UINPUT
                "bluetoothHid" -> BLUETOOTH_HID
                else -> null
            }
        }
    }
}

/**
 * Base interface for keyboard backends.
 */
interface IKeyboardBackend {
    val isAvailable: Boolean
    val isInitialized: Boolean
    val isConnected: Boolean

    fun initialize(): Boolean
    fun cleanup()
    fun getStatus(): Map<String, Any?>
    fun sendKeyEvent(
        keyCode: Int,
        shift: Boolean,
        ctrl: Boolean,
        alt: Boolean,
        meta: Boolean,
        isDown: Boolean?
    ): Boolean
    fun typeText(text: String): Boolean
}
