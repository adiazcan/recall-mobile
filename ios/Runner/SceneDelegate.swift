import Flutter
import UIKit
import MSAL

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let urlContext = URLContexts.first else {
      super.scene(scene, openURLContexts: URLContexts)
      return
    }

    let sourceApplication = urlContext.options.sourceApplication ?? ""
    let handled = MSALPublicClientApplication.handleMSALResponse(
      urlContext.url,
      sourceApplication: sourceApplication
    )

    if !handled {
      super.scene(scene, openURLContexts: URLContexts)
    }
  }
}
