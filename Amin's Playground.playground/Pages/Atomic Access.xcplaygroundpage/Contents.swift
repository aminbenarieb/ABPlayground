/*:
 ### Atomic accces
 */

import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let useLocks = true

var counter: Int = 0

func incrementCounter(contextName: String) {
    let originalCounterValue = counter
    counter = counter + 1
    if counter != originalCounterValue + 1 {
        fatalError("\(contextName):\(counter) Another caller got in here and stepped on our data! ")
    }
    else {
        print("\(contextName):\(counter) OK")
    }
}

let lockQueue = DispatchQueue(label: "lock")

func callIncrement(name: String, useLock: Bool) {
    if useLock {
        lockQueue.async {
            incrementCounter(contextName: name)
        }
    }
    else {
        incrementCounter(contextName: name)
    }
}

DispatchQueue.global(qos: .background).async {
    for _ in 0..<100 {
        callIncrement(name: "ONE", useLock: useLocks)
    }
}

DispatchQueue.global(qos: .background).async {
    for _ in 0..<100 {
        callIncrement(name: "TWO", useLock: useLocks)
    }
}

//: [Next](@next)
