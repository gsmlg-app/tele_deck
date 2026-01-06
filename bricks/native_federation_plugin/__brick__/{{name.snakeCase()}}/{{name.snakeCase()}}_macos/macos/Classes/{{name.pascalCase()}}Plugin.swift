import Cocoa
import FlutterMacOS

public class {{name.pascalCase()}}Plugin: NSObject, FlutterPlugin {
    private var cachedData: [String: Any]?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
            binaryMessenger: registrar.messenger
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

        let processInfo = ProcessInfo.processInfo
        let data: [String: Any] = [
            "platform": "macos",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "additionalData": [
                "hostName": processInfo.hostName,
                "operatingSystemVersion": "\(processInfo.operatingSystemVersion.majorVersion).\(processInfo.operatingSystemVersion.minorVersion).\(processInfo.operatingSystemVersion.patchVersion)",
                "operatingSystemVersionString": processInfo.operatingSystemVersionString,
                "processorCount": processInfo.processorCount,
                "activeProcessorCount": processInfo.activeProcessorCount,
                "physicalMemory": processInfo.physicalMemory
            ]
        ]

        cachedData = data
        return data
    }
}
