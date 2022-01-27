import UIKit
import NSLogger

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // logging some messages
        Logger.shared.log(.network, .info, "Checking paper level…")

        // logging image
        if let myPrettyImage = UIImage(named: "log_img")?.cgImage {
            Logger.shared.log(.view, .noise, Image(cgImage: myPrettyImage))
        }
        
        return true
    }

}
