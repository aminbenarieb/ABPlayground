import Foundation
import UIKit
import SnapKit
import SwiftUI

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

class ScrollViewControllerBottomToastToBottomAssembly {
    func create() -> UIViewController {
        UINavigationController(rootViewController: ScrollViewControllerBottomToast())
    }
}

class ScrollViewControllerBottomToast: UIViewController {
  
   // MARK: Views
  
  private lazy var scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.alwaysBounceHorizontal = false
    return sv
  }()
  
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
  
    private lazy var sellingInformerView = SellingInformerView()
  
    // MARK: Lifecycle
  
    override func viewDidLoad() {
      super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    
    // MARK: -
  
    func setupViews() {
      view.backgroundColor = .white
      
      // START: ScrollView
      view.addSubview(scrollView)
      scrollView.delegate = self
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.snp.makeConstraints { make in
          make.size.equalToSuperview()
          make.edges.equalToSuperview()
      }
      // END
  
      // START: Selling Informer
      let viewModel = SellingInformerViewModelImpl()
      viewModel.userProfileService = WTUserProfileService()
      self.sellingInformerView.viewModel = viewModel
      self.sellingInformerView.configure(under: view,
                                         configuration: SellingInformerView.Configuration(
          displayAction: { (state) in
            
          },
          targetAction: {
            
          },
          bottomInset: 0
        )
      )
      // END
      
      // START: StackView
      scrollView.addSubview(stackView)
      stackView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      
      for i in 0..<10 {
        let color = UIColor.random
        let stubView = UIView()
        stubView.backgroundColor = color
        stackView.addArrangedSubview(stubView)
        stubView.snp.makeConstraints { make in
          make.size.equalTo(view.frame.height)
          make.width.equalTo(view.frame.width)
        }
        let label = UILabel()
        label.text = "\(i+1)"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 50)
        stubView.addSubview(label)
        label.snp.makeConstraints { make in
          make.edges.equalToSuperview()
        }
      }
      // END
    }
    
}

extension ScrollViewControllerBottomToast: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) { // any offset changes
        print("scrolling.playground", "scrollViewDidScroll")
      self.sellingInformerView.scrollViewDidScroll(scrollView)
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
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print("scrolling.playground", "scrollViewDidScrollToTop")
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        false
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {// called on finger up as we are moving
        print("scrolling.playground", "scrollViewWillBeginDecelerating")
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
    
}

