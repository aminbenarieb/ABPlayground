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
        self.storage.forEach { body($0 as! Element) }
    }

    public func contains(_ element: Element) -> Bool {
        return self.index(of: element) != nil
    }

    public func index(of element: Element) -> Int? {
        let index = self.storage.index(
            of: element,
            inSortedRange: NSRange(0..<self.storage.count),
            usingComparator: self.compareElement
        )
        return index == NSNotFound ? nil : index
    }

    public func bisect_key_left(key: Key) -> Int {
        return self.storage.index(
            of: key,
            inSortedRange: NSRange(0..<self.storage.count),
            options: [.insertionIndex, .firstEqual],
            usingComparator: self.compareElementAndKey
        )
    }

    public func bisect_key_right(key: Key) -> Int {
        return self.storage.index(
            of: key,
            inSortedRange: NSRange(0..<self.storage.count),
            options: [.insertionIndex, .lastEqual],
            usingComparator: self.compareElementAndKey
        )
    }

    fileprivate func compareElementAndKey(_ a: Any, _ b: Any) -> ComparisonResult {
        func anyToKey(_ object: Any) -> Key {
            return (object as? Key) ?? self.elementToKey(object as! Element)
        }
        let a = anyToKey(a), b = anyToKey(b)
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    fileprivate func compareKey(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = a as! Key, b = b as! Key
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }

    fileprivate func compareElement(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = self.elementToKey(a as! Element), b = self.elementToKey(b as! Element)
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
        return self.storage.contains(element) || self.index(of: element) != nil
    }
}

extension OrderedKeyArray: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.storage.count }
    public subscript(i: Int) -> Element { return self.storage[i] as! Element }
}

extension OrderedKeyArray {
    @discardableResult
    public mutating func insert(_ newElement: Element)
        -> (inserted: Bool, memberAfterInsert: Element)
    {
        let index = self.index(for: newElement)
//        if index < storage.count, storage[index] as! Element == newElement {
//            return (false, storage[index] as! Element)
//        }
        self.makeUnique()
        self.storage.insert(newElement, at: index)
        return (true, newElement)
    }

    public mutating func remove(_ element: Element) -> Bool {
        guard let index = self.index(of: element) else {
            return false
        }
        self.makeUnique()
        self.storage.removeObject(at: index)
        return true
    }

    fileprivate func index(for value: Element) -> Int {
        return self.storage.index(
            of: value,
            inSortedRange: NSRange(0..<self.storage.count),
            options: .insertionIndex,
            usingComparator: self.compareElement
        )
    }

    fileprivate mutating func makeUnique() {
        print("isKnownUniquelyReferenced: \(isKnownUniquelyReferenced(&self.canary))")
        if !isKnownUniquelyReferenced(&self.canary) {
            self.storage = self.storage.mutableCopy() as! NSMutableArray
            self.canary = Canary()
        }
    }
}
