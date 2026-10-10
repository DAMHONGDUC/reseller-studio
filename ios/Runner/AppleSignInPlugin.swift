import AuthenticationServices
import CryptoKit
import Flutter
import UIKit

/// Sign in with Apple, presented from the window Flutter is drawing in.
///
/// FlutterFire's own Apple path looks for a key window across the connected
/// scenes and, finding none, presents from no window at all — the sheet never
/// appears and the call never answers. App Review hit exactly that on an iPad
/// (build 34), so the app owns the presentation instead.
///
/// - The anchor is the Flutter view's own window, found before the request
///   runs; with no window the call fails at once rather than waiting forever.
/// - Every path answers exactly once: a credential, `canceled`, or an error.
/// - The nonce is made here and only its hash goes to Apple; Dart gets the
///   raw value to hand Firebase, which checks the two match.
final class AppleSignInPlugin: NSObject, FlutterPlugin {
  private static let channelName = "app.dd.reseller.studio/apple_sign_in"

  private weak var registrar: FlutterPluginRegistrar?
  private var pending: FlutterResult?
  private var rawNonce: String?
  private var anchor: UIWindow?
  // Held so the request outlives the method call that started it.
  private var controller: ASAuthorizationController?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())
    let instance = AppleSignInPlugin(registrar: registrar)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "requestCredential" else {
      result(FlutterMethodNotImplemented)
      return
    }

    requestCredential(result: result)
  }

  private func requestCredential(result: @escaping FlutterResult) {
    if pending != nil {
      result(FlutterError(code: "in-progress", message: "A request is already running", details: nil))
      return
    }

    guard let window = presentationWindow() else {
      result(FlutterError(code: "no-window", message: "No window to present from", details: nil))
      return
    }

    let nonce = Self.randomNonce()
    let request = ASAuthorizationAppleIDProvider().createRequest()
    let controller = ASAuthorizationController(authorizationRequests: [request])

    request.requestedScopes = [.fullName, .email]
    request.nonce = Self.sha256(nonce)
    pending = result
    rawNonce = nonce
    anchor = window
    self.controller = controller
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
  }

  /// The Flutter view's window first; any scene's visible window after it.
  private func presentationWindow() -> UIWindow? {
    if let window = registrar?.viewController?.view.window {
      return window
    }

    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let ordered =
      scenes.filter { $0.activationState == .foregroundActive }
      + scenes.filter { $0.activationState != .foregroundActive }

    for scene in ordered {
      if let window = scene.windows.first(where: { $0.isKeyWindow })
        ?? scene.windows.first(where: { !$0.isHidden })
      {
        return window
      }
    }

    return nil
  }

  private func finish(_ value: Any?) {
    let result = pending

    pending = nil
    rawNonce = nil
    anchor = nil
    controller = nil
    result?(value)
  }

  private static func randomNonce(length: Int = 32) -> String {
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

    if status != errSecSuccess {
      return UUID().uuidString + UUID().uuidString
    }

    return String(bytes.map { charset[Int($0) % charset.count] })
  }

  private static func sha256(_ input: String) -> String {
    SHA256.hash(data: Data(input.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
  }
}

extension AppleSignInPlugin: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard
      let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
      let tokenData = credential.identityToken,
      let idToken = String(data: tokenData, encoding: .utf8),
      let nonce = rawNonce
    else {
      finish(FlutterError(code: "invalid-credential", message: "Apple returned no identity token", details: nil))
      return
    }

    finish([
      "idToken": idToken,
      "rawNonce": nonce,
      "givenName": credential.fullName?.givenName,
      "familyName": credential.fullName?.familyName,
    ])
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    let nsError = error as NSError

    if nsError.domain == ASAuthorizationError.errorDomain,
      nsError.code == ASAuthorizationError.canceled.rawValue
    {
      finish(FlutterError(code: "canceled", message: nil, details: nil))
      return
    }

    finish(
      FlutterError(
        code: "authorization-failed",
        message: "\(nsError.domain) \(nsError.code)",
        details: nil))
  }
}

extension AppleSignInPlugin: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    anchor ?? presentationWindow() ?? ASPresentationAnchor()
  }
}
