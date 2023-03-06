import UIKit
import os
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
                
        let logger = Logger.init(subsystem: "amin.benarieb.playground", category: "main")
        logger.log("Bank account number \(1234123412341234, privacy: .private(mask: .hash))")
        logger.trace("Bank account number \(1234123412341234, privacy: .private(mask: .hash))")

        
        return true
    }

}
