import Flutter
import UIKit

public class TeleCrashLoggerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "tele_tele_crash_logger",
            binaryMessenger: registrar.messenger()
        )
        let instance = TeleCrashLoggerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getData":
            let device = UIDevice.current
            let data: [String: Any] = [
                "platform": "ios",
                "systemName": device.systemName,
                "systemVersion": device.systemVersion,
                "model": device.model,
                "name": device.name
            ]
            result(data)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
