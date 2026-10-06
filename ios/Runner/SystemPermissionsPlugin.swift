import AVFoundation
import Flutter
import Photos
import UIKit
import UserNotifications

/// Whether iOS will still ask for a permission, and the way to its Settings page.
///
/// iOS shows each permission dialog once; after a refusal the only way back
/// is the app's page in Settings, so a refusal here is always for good.
/// - `isBlocked` answers for `camera`, `photos` or `notifications`.
/// - `openAppSettings` opens this app's page and answers whether it opened.
final class SystemPermissionsPlugin: NSObject, FlutterPlugin {
  private static let channelName = "app.dd.reseller.studio/system_permissions"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())

    registrar.addMethodCallDelegate(SystemPermissionsPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isBlocked":
      let permission = (call.arguments as? [String: Any])?["permission"] as? String
      isBlocked(permission, result: result)
    case "openAppSettings":
      openAppSettings(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isBlocked(_ permission: String?, result: @escaping FlutterResult) {
    switch permission {
    case "camera":
      let status = AVCaptureDevice.authorizationStatus(for: .video)
      result(status == .denied || status == .restricted)
    case "photos":
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      result(status == .denied || status == .restricted)
    case "notifications":
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async { result(settings.authorizationStatus == .denied) }
      }
    default:
      result(FlutterError(code: "unknown-permission", message: "Unknown permission", details: permission))
    }
  }

  private func openAppSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(false)
      return
    }

    UIApplication.shared.open(url) { opened in result(opened) }
  }
}
