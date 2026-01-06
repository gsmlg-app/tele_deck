import Flutter
import UIKit

public class {{name.pascalCase()}}Plugin: NSObject, FlutterPlugin {
    private var cachedData: [String: Any]?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
            binaryMessenger: registrar.messenger()
        )
        let instance = {{name.pascalCase()}}Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getData":
            do {
                let data = try getData()
                result(data)
            } catch {
                result(FlutterError(
                    code: "ERROR",
                    message: "Failed to get data: \(error.localizedDescription)",
                    details: nil
                ))
            }
        case "refresh":
            cachedData = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getData() throws -> [String: Any] {
        if let cached = cachedData {
            return cached
        }

        let device = UIDevice.current
        let data: [String: Any] = [
            "platform": "ios",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "additionalData": [
                "name": device.name,
                "model": device.model,
                "systemName": device.systemName,
                "systemVersion": device.systemVersion,
                "localizedModel": device.localizedModel,
                "identifierForVendor": device.identifierForVendor?.uuidString ?? "",
                "isPhysicalDevice": isPhysicalDevice()
            ]
        ]

        cachedData = data
        return data
    }

    private func isPhysicalDevice() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}
