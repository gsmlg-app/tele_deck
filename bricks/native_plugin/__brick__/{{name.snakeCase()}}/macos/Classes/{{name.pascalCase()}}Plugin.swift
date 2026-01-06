import Cocoa
import FlutterMacOS

public class {{name.pascalCase()}}Plugin: NSObject, FlutterPlugin {
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
            let processInfo = ProcessInfo.processInfo
            let data: [String: Any] = [
                "platform": "macos",
                "operatingSystemVersion": processInfo.operatingSystemVersionString,
                "hostName": processInfo.hostName,
                "processName": processInfo.processName,
                "processorCount": processInfo.processorCount
            ]
            result(data)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
