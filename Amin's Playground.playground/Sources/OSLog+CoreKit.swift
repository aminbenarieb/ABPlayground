import CoreGraphics
import Foundation
import os.log

@available(iOS 10.0, *)
public extension OSLog {
    private static let subsystem = "celly.corekit"
    static let tests = OSLog(
        subsystem: subsystem,
        category: "tests"
    )
    #if CELLYDEV
        static let corekit = OSLog(
            subsystem: subsystem,
            category: "corekit"
        )
    #else
        static let corekit = OSLog.disabled
    #endif
}
