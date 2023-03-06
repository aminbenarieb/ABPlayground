//: [Previous](@previous)

import SwiftUI

let preview = UIView()
preview.frame = CGRect(x: 0, y: 0, width: 320, height: 700)
preview.backgroundColor = .blue
let gradientLayer = CAGradientLayer()
gradientLayer.frame = CGRect(x: 0, y: 0, width:  preview.bounds.width, height: 200)
gradientLayer.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
gradientLayer.locations = [0.0, 0.5, 1.0]
gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
let backgroundView = UIView()
backgroundView.frame = CGRect(x: 0, y: preview.bounds.height + 200, width:  preview.bounds.width, height: 200)
backgroundView.layer.addSublayer(gradientLayer)
let someView = UIView()
someView.frame = CGRect(x: (backgroundView.bounds.width-250)/2, y: backgroundView.bounds.height - 125 - 32, width: 250, height: 125)
someView.backgroundColor = .green
backgroundView.addSubview(someView)
preview.addSubview(backgroundView)

let opacityAnimationParams = (fromValue: Float(0), toValue: Float(1))
let postionAnimationParams = (fromValue: backgroundView.layer.position.y,
                              toValue: preview.frame.height - 100)
CATransaction.begin()
CATransaction.setCompletionBlock({
 backgroundView.isHidden = opacityAnimationParams.toValue == 0
 backgroundView.layer.position.y = postionAnimationParams.toValue
 backgroundView.layer.opacity = opacityAnimationParams.toValue
  print("\(backgroundView.isHidden)", "\(postionAnimationParams)", "\(opacityAnimationParams))")
  preview
})

let translationAnimation = CABasicAnimation(keyPath: "position.y")
translationAnimation.fromValue = postionAnimationParams.fromValue
translationAnimation.toValue = postionAnimationParams.toValue
let opacityAnimation = CABasicAnimation(keyPath: "opacity")
opacityAnimation.fromValue = opacityAnimationParams.fromValue
opacityAnimation.toValue = opacityAnimationParams.toValue

let group = CAAnimationGroup()
group.duration = 0.2
group.timingFunction = CAMediaTimingFunction(name: .easeOut)
group.animations = [translationAnimation, opacityAnimation];

backgroundView.layer.add(group, forKey: "displayAnimation")
CATransaction.commit()



//struct BannerView: View {
//    var body: some View {
//        ZStack {
//            // Blur background
//            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
//                .edgesIgnoringSafeArea(.all)
//
//            HStack {
//                // Calendar icon on left
//                Image(systemName: "calendar")
//                    .font(.title)
//
//                Spacer()
//
//                // Title label on top
//                Text("TITLE")
//                    .font(.title)
//                    .foregroundColor(.white)
//
//                Spacer()
//
//                // Close button on top right
//                Button(action: {}) {
//                    Image(systemName: "xmark")
//                        .font(.title)
//                        .foregroundColor(.white)
//                }
//
//            }
//            .padding(.horizontal)
//
//            // Button on bottom
//            VStack {
//                Spacer()
//
//                Button(action: {}) {
//                    Text("BUTTON")
//                        .foregroundColor(.white)
//                        .font(.headline)
//                }
//                .padding()
//                .background(Color.red)
//                .cornerRadius(10)
//
//            }
//        }
//    }
//}
//
//// View to create a blur effect
//struct VisualEffectView: UIViewRepresentable {
//    var effect: UIVisualEffect?
//
//    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
//        return UIVisualEffectView(effect: effect)
//    }
//
//    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
//        uiView.effect = effect
//    }
//}


//: [Next](@next)
