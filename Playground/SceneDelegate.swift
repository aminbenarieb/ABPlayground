import Foundation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        window = UIWindow(windowScene: scene as! UIWindowScene)
        window?.frame = UIScreen.main.bounds
        window?.rootViewController = ScrollViewViewControllerAssembly().create()
        window?.makeKeyAndVisible()
    }
}

