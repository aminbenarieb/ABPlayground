import Foundation

private class Canary {}

public struct OrderedSet<Element: Comparable /* & Hashable & Equatable*/>: SortedSet {
    fileprivate var storage = NSMutableOrderedSet()
    fileprivate var canary = Canary()
    public init() {}

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
            usingComparator: OrderedSet.compare
        )
        return index == NSNotFound ? nil : index
    }

    fileprivate static func compare(_ a: Any, _ b: Any) -> ComparisonResult {
        let a = a as! Element, b = b as! Element
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
}

extension OrderedSet {
    public func contains2(_ element: Element) -> Bool {
        // undefined usage of NSObject hashing
        // propably element should be Equatable & Hashable
        // so generated private nsobject class
        // would have some hashing / equality
        // implementations
        return self.storage.contains(element) // || index(of: element) != nil
    }
}

extension OrderedSet: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.storage.count }
    public subscript(i: Int) -> Element { return self.storage[i] as! Element }
}

extension OrderedSet {
    @discardableResult
    public mutating func insert(_ newElement: Element)
        -> (inserted: Bool, memberAfterInsert: Element)
    {
        let index = self.index(for: newElement)
        if index < self.storage.count, self.storage[index] as! Element == newElement {
            return (false, self.storage[index] as! Element)
        }
        self.makeUnique()
        self.storage.insert(newElement, at: index)
        return (true, newElement)
    }

    fileprivate func index(for value: Element) -> Int {
        return self.storage.index(
            of: value,
            inSortedRange: NSRange(0..<self.storage.count),
            options: .insertionIndex,
            usingComparator: OrderedSet.compare
        )
    }

    fileprivate mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&self.canary) {
            self.storage = self.storage.mutableCopy() as! NSMutableOrderedSet
            self.canary = Canary()
        }
    }
}
