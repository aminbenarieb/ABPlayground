import Foundation

public class CellyError: Error, LocalizedError {
    private var message: String

    public var errorDescription: String? {
        return self.message
    }

    public init(message: String) {
        self.message = message
    }
}
