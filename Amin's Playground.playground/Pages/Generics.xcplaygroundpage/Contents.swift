//: [Previous](@previous)

import Foundation
import UIKit

var str = "Hello, playground"

func log<View: UIView>(_ view: View) {
print("It's a \(type(of: view)), frame: \(view.frame)")
}
func log(_ view: UILabel) {
let text = view.text ?? "(empty)"
print("It's a label, text: \(text)")
}

let label = UILabel(frame: CGRect(x: 20, y: 20, width: 200, height: 32))
label.text = "Password"
log(label) // It's a label, text: Password
let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
log(button) // It's a UIButton, frame: (0.0, 0.0, 100.0, 50.0)”

let views = [label, button] // Type of views is [UIView]
for view in views {
log(view)
}

for view in [label, label] {
log(view)
}

//: [Next](@next)
