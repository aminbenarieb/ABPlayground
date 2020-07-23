//: [Previous](@previous)

import Foundation

/*:
### OrderedSet
*/

//struct Value: Hashable & Comparable {
//let value: Int
//init(_ value: Int) { self.value = value }
//
//static func ==(left: Value, right: Value) -> Bool {
//return left.value == right.value
//}
//
//static func <(left: Value, right: Value) -> Bool {
//return left.value < right.value
//}
//}
//
//var set = OrderedSet<Value>()
//for i in (1 ... 20).shuffled().map({ Value($0) }) {
//set.insert(i)
//}
//print(set)
//set.contains2(Value(7))
//set.contains2(Value(-42))
//print(set.map { $0 * -1 }.reduce(0, +))
//let copy = set
//set.insert(42)
//print(copy)
//print(set)

/*:
### OrderedKeySet
*/

struct ValueKeyed: Hashable {
    typealias Key = Int
    var value: String
    var key: Key
}

var collectionKey = OrderedKeyArray<ValueKeyed.Key, ValueKeyed>() { $0.key }
print(collectionKey.isEmpty)
for i in (1 ... 20).shuffled().map({ ValueKeyed(value: "\($0)", key: $0) }) {
    collectionKey.insert(i)
}
print(collectionKey.isEmpty)
collectionKey.contains2(ValueKeyed(value: "7", key: 7))
for i in (1 ... 20).shuffled().map({ ValueKeyed(value: "\($0)", key: $0) }) {
    collectionKey.remove(i)
}
print(collectionKey.isEmpty)
//collectionKey.insert(ValueKeyed(value: "7", key: 7))
//collectionKey.insert(ValueKeyed(value: "7", key: 7))
//
//print(collectionKey)
//
//collectionKey.bisect_key_left(key: 7)
//collectionKey.bisect_key_left(key: -42)
//collectionKey.bisect_key_left(key: 42)
//
//collectionKey.bisect_key_right(key: 7)
//collectionKey.bisect_key_right(key: -42)
//collectionKey.bisect_key_right(key: 42)
//
//
//: [Next](@next)
