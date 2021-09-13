//: [Previous](@previous)

import Foundation

var int = 1
var int2 = int
address(&arr)
address(&arr2)


var arr = [1,2,3]
var arr2 = arr
address(&arr)
address(&arr2)

var str = "Hello, playground"
var str2 = str
address(&str)
address(&str2)

var abc = ABC(str: str)
var abc2 = abc
address(&abc)
address(&abc2)

// Manual CoW

// ABC
var abcBox = Box(abc)
var abcBox2 = abcBox

address(&abcBox.ref.val)
address(&abcBox2.ref.val)

abcBox2.value = ABC(str: "New Value")

address(&abcBox.ref.val)
address(&abcBox2.ref.val)

// str

var strBox = Box(str)
var strBox2 = strBox

address(&strBox.ref.val)
address(&strBox2.ref.val)

strBox2.value = "New Value"

address(&strBox.ref.val)
address(&strBox2.ref.val)

// ===

struct ABC {
  var str: String
  init(str: String) { self.str = str; print("ABC init \(str) called") }
}

final class Ref<T> {
  var val: T
  init(_ v: T) {val = v;  print("Ref init \(val) called") }
}

struct Box<T> {
    var ref: Ref<T>
  init(_ x: T) { ref = Ref(x); print("Box init \(ref) called") }

    var value: T {
        get { return ref.val }
        set {
          if !isKnownUniquelyReferenced(&ref) {
            ref = Ref(newValue)
            return
          }
          ref.val = newValue
        }
    }
}

func address(_ a: UnsafeRawPointer) {
  print(NSString(format: "%p", Int(bitPattern: a)))
}


//: [Next](@next)
