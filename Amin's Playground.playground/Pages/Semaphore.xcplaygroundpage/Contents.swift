import Foundation

let semaphore = DispatchSemaphore(value: 1)
let queue = DispatchQueue(
    label: "amin.benarieb.queue",
    attributes: [.concurrent]
)
for i in 0..<10 {
    queue.async {
        print("\(i): requested")
        guard semaphore.wait(timeout: .now()) == .success else {
            print("\(i): dropped")
            return
        }
        print("\(i): started")
        usleep(1000 * 1000 * 1)
        print("\(i): finished")
        semaphore.signal()
    }
}
