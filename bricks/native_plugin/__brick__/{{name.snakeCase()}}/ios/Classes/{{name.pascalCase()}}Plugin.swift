import Flutter
import UIKit

public class {{name.pascalCase()}}Plugin: NSObject, FlutterPlugin {
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
