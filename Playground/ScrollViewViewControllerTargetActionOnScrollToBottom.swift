import Foundation
import UIKit
import SnapKit

//struct StubViewInfo {
//    let size: CGSize
//    let backgroundColor: UIColor
//}

private extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

enum ScrollDirection {
    case none
    case top
    case bottom
}

func NL(_ key: String) -> String {
    key
}

private enum Constants {
   
    static let showContentSpeedSeconds: CGFloat = envVal(NL("duration"), 0.3)
    static let showContentDelaySeconds: CGFloat = envVal(NL("delay"), 0)
    
    // Start: FIXME: Delete
    static func envVal(_ key: String, _ defaultVal: CGFloat) -> CGFloat {
        guard let valRaw = ProcessInfo.processInfo.environment[key], let val = Float(valRaw) else {
            return defaultVal
        }
        return CGFloat(val)
    }
    // End
}

class ScrollViewViewControllerTargetActionOnScrollToBottomAssembly {
    func create() -> UIViewController {
        UINavigationController(rootViewController: ScrollViewViewControllerTargetActionOnScrollToBottom())
    }
}

class ScrollViewViewControllerTargetActionOnScrollToBottom: UIViewController {
    
    private var topView: UIView!
    private var bottomView: UIView!
    
    private let scrollView = UIScrollView()
    private var scrollDirection: ScrollDirection = .none
    private var scrollLastContentOffset: CGPoint = .zero
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
      super.viewDidLoad()
        view.backgroundColor = .white
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        printDefaultEasingFunctionsValues()
       setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: -
    
    func printDefaultEasingFunctionsValues() {
        let cords: UnsafeMutablePointer<Float> = UnsafeMutablePointer.allocate(capacity: 2)
        let defaultTimingFunctionOptions = [CAMediaTimingFunctionName.linear,
                                            CAMediaTimingFunctionName.easeIn,
                                            CAMediaTimingFunctionName.easeOut,
                                            CAMediaTimingFunctionName.easeInEaseOut,
                                            CAMediaTimingFunctionName.default]

        var timingFunctions = defaultTimingFunctionOptions.map({ CAMediaTimingFunction(name: $0) })
        timingFunctions.append(CAMediaTimingFunction(controlPoints: 0.42, 0, 0.58, 1.00))
        for timingFunction in timingFunctions {
            print("\n" + timingFunction.description)

            for i in 0..<4 {
                timingFunction.getControlPoint(at: i, values: cords)
                print("(x:\(cords[0]) y:\(cords[1]))")
            }
        }
    }
    
    func setupViews() {
        func add(_ size: CGSize) -> UIView {
            let stubView = UIView()
            let color = UIColor.random
            stubView.backgroundColor = color
            stubView.snp.makeConstraints { make in
                make.size.equalTo(size)
            }
            stackView.addArrangedSubview(stubView)
            return stubView
        }
        
        let arrangedSubviews = stackView.arrangedSubviews
        for arrangedSubview in arrangedSubviews {
            stackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
        topView = add(CGSize(width: view.frame.width, height: view.frame.height*0.7))
        bottomView = add(CGSize(width: view.frame.width, height: view.frame.height*1.5))
        self.bottomView.alpha = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.targetAction2()
        })
    }
    
    // MARK: Motion shake (refresh action)
    
    // We are willing to become first responder to get shake motion
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            setupViews()
        }
    }
    
}

extension ScrollViewViewControllerTargetActionOnScrollToBottom: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) { // any offset changes
        print("scrolling.playground", "scrollViewDidScroll")
        let contentOffset = scrollView.contentOffset
        if scrollLastContentOffset.y > contentOffset.y {
            scrollDirection = .top
        }
        else if scrollLastContentOffset.y < contentOffset.y {
            scrollDirection = .bottom
        }
        else {
            scrollDirection = .none
        }
        scrollLastContentOffset = contentOffset
        
//        if targetCondition() {
//            targetAction()
//        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("scrolling.playground", "scrollViewWillBeginDragging")
    }

    // called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print("scrolling.playground", "scrollViewWillEndDragging")
    }

    // called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("scrolling.playground", "scrollViewDidEndDragging")
//        if targetCondition() {
//            targetAction()
//        }
    }


    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print("scrolling.playground", "scrollViewDidScrollToTop")
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        false
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {// called on finger up as we are moving
        print("scrolling.playground", "scrollViewWillBeginDecelerating")
        if targetCondition() {
            targetAction()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { // called when scroll view grinds to a halt
        print("scrolling.playground", "scrollViewDidEndDecelerating")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
        print("scrolling.playground", "scrollViewDidEndScrollingAnimation")
    }
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        print("scrolling.playground", "scrollViewDidChangeAdjustedContentInset")
    }

    // MARK: -
    
    func targetAction() {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        
        /// UIView.animation: frame
//        print("scrolling.playground", "self.stackView.frame.origin (s)", self.stackView.frame.origin)
//        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
////                 scrollView.contentOffset = scrollView.contentOffset.applying(CGAffineTransform(translationX: 0, y: scrollView.frame.height * 0.75))
//            self.stackView.frame = self.stackView.frame.offsetBy(dx: 0, dy: -self.stackView.frame.height * 0.30)
//        } completion: { _ in
//            print("scrolling.playground", "self.stackView.frame.origin (f)", self.stackView.frame.origin)
////            self.navigationController?.pushViewController(ScrollViewViewController(), animated: false)
//            // self.stackView.frame = CGRect(origin: .zero, size: self.stackView.frame.size)
//        }
        
        /// CABasicAnimation
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            let bottomOffset = CGPoint(x: 0, y: self!.scrollView.contentSize.height - self!.scrollView.bounds.size.height)
            self?.scrollView.setContentOffset(bottomOffset, animated: false)
            self?.stackView.layer.removeAnimation(forKey: "scrollAnimation")
        }
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = -self.stackView.frame.height * 0.3
        animation.duration = 1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards;
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.stackView.layer.add(animation, forKey: "scrollAnimation")
        CATransaction.commit()
        
        
        //rectangle.layer.position = CGPointMake(150, 0);
        
        /// UIView.animation: CGAffineTransform
//        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
//            self.stackView.transform = CGAffineTransform(translationX: 0, y: -self.stackView.frame.height * 0.3)
//        } completion: { _ in
//            self.stackView.transform = .identity
//        }
        
    }
    
    func targetCondition() -> Bool {
        let diff = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.frame.height)
        return scrollDirection == .bottom && diff < -100
    }
    
    func targetAction2() {
        // initial
        let intersection = self.bottomView.frame.intersection(self.scrollView.frame)
        let diff = intersection.height
        print(String(format: "diff (expected): %0.1lf", 106.5))
        print(String(format: "diff (got): %0.1lf", diff))

        /// UIView.animation
//        self.stackView.setCustomSpacing(diff, after: self.topView)
//        UIView.animate(withDuration: 0.3, delay: 0,options: UIView.AnimationOptions.curveEaseInOut) {
//            self.stackView.setCustomSpacing(0, after: self.topView)
//            self.bottomView.alpha = 1
//        }
        
        /// CABasicAnimation
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.bottomView.alpha = 1
            self?.bottomView.layer.removeAnimation(forKey: "scroll2Animation")
        }
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = 1
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let translationAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        translationAnimation.fromValue = diff
        translationAnimation.toValue = 0
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        
        groupAnimation.animations = [translationAnimation, fadeAnimation]
        bottomView.layer.add(groupAnimation, forKey: "scroll2Animation")
        CATransaction.commit()
    }
    
}
