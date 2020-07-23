import Foundation

private class Canary {}

public struct OrderedKeyArray<Key: Comparable, Element: Hashable & Equatable> {
    fileprivate var storage = NSMutableArray()
    fileprivate var canary = Canary()
    fileprivate let elementToKey: ElementToKey; public typealias ElementToKey = (Element) -> (Key)

    public init(elementToKey: @escaping ElementToKey) {
        self.elementToKey = elementToKey
    }

    public func forEach(_ body: (Element) -> Void) {
        storage.forEach { body($0 as! Element) }
    }

    public func contains(_ element: Element) -> Bool {
        return index(of: element) != nil
    }

    public func index(of element: Element) -> Int? {
        let index = storage.index(
            of: element,
            inSortedRange: NSRange(0 ..< storage.count),
            usingComparator: self.compareElement)
        return index == NSNotFound ? nil : index
    }

    public func bisect_key_left(key: Key) -> Int {
        return storage.index(
            of: key,
            inSortedRange: NSRange(0 ..< storage.count),
            options: [.insertionIndex, .firstEqual],
            usingComparator: self.compareElementAndKey
        )
    }

    public func bisect_key_right(key: Key) -> Int {
        return storage.index(
            of: key,
            inSortedRange: NSRange(0 ..< storage.count),
            options: [.insertionIndex, .lastEqual],
            usingComparator: self.compareElementAndKey
        )
    }

    fileprivate func compareElementAndKey(_ a: Any, _ b: Any) -> ComparisonResult {
        func anyToKey(_ object: Any) -> Key {
            return (object as? Key) ?? elementToKey(object as! Element)
        }
        let a = anyToKey(a), b = anyToKey(b)
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    fileprivate func compareKey(_ a: Any, _ b: Any) -> ComparisonResult
    {
        let a = a as! Key, b = b as! Key
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    fileprivate func compareElement(_ a: Any, _ b: Any) -> ComparisonResult
    {
        let a = elementToKey(a as! Element), b = elementToKey(b as! Element)
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
}

extension OrderedKeyArray {
    public func contains2(_ element: Element) -> Bool {
        // undefined usage of NSObject hashing
        // propably element should be Equatable & Hashable
        // so generated private nsobject class
        // would have some hashing / equality
        // implementations
        return storage.contains(element) || index(of: element) != nil
    }
}

extension OrderedKeyArray: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return storage.count }
    public subscript(i: Int) -> Element { return storage[i] as! Element }
}

extension OrderedKeyArray {
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
    {
        let index = self.index(for: newElement)
//        if index < storage.count, storage[index] as! Element == newElement {
//            return (false, storage[index] as! Element)
//        }
        makeUnique()
        storage.insert(newElement, at: index)
        return (true, newElement)
    }

    public mutating func remove(_ element: Element) -> Bool {
        guard let index = self.index(of: element) else {
            return false
        }
        makeUnique()
        storage.removeObject(at: index)
        return true
    }

    fileprivate func index(for value: Element) -> Int {
        return storage.index(
            of: value,
            inSortedRange: NSRange(0 ..< storage.count),
            options: .insertionIndex,
            usingComparator: self.compareElement)
    }

    fileprivate mutating func makeUnique() {
        print("isKnownUniquelyReferenced: \(isKnownUniquelyReferenced(&canary))")
        if !isKnownUniquelyReferenced(&canary) {
            storage = storage.mutableCopy() as! NSMutableArray
            canary = Canary()
        }
    }
}
