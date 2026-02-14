import Flutter
import UIKit
import MSAL

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register method channel for pending shared URLs from Share Extension
    let pendingUrlsChannel = FlutterMethodChannel(
      name: "com.recall.mobile/pendingUrls",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    pendingUrlsChannel.setMethodCallHandler { (call, result) in
      let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String ?? "group.com.recall.mobile"
      let defaults = UserDefaults(suiteName: appGroupId)

      switch call.method {
      case "getPendingUrls":
        let urls = defaults?.stringArray(forKey: "pendingSharedURLs") ?? []
        result(urls)
      case "clearPendingUrls":
        defaults?.removeObject(forKey: "pendingSharedURLs")
        defaults?.synchronize()
        result(nil)
      case "syncAuthConfig":
        // Store token + API base URL in shared UserDefaults so the
        // Share Extension can make authenticated API calls directly.
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected map", details: nil))
          return
        }
        let token = args["accessToken"] as? String
        let apiBaseUrl = args["apiBaseUrl"] as? String
        defaults?.set(token, forKey: "shareExtensionAccessToken")
        defaults?.set(apiBaseUrl, forKey: "shareExtensionApiBaseUrl")
        defaults?.synchronize()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
      return super.application(app, open: url, options: options)
    }
    return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: sourceApplication)
  }
}
