import SwiftUI
import UIKit

class SellingInformerView: UIView {

    // START: Definitions
    struct Configuration {
        let displayAction: (SellingInformerState.Info) -> (Void)
        let targetAction: () -> (Void)

        let bottomInset: CGFloat
    }

    struct Constants {
        static let displayAnimationKey = "displayAnimation"
        static let backgroundGradientKey = "backgroundGradient"
    }
    // END

    // START: Properties
    var viewModel: SellingInformerViewModel!
    private var configuration: Configuration?

    private var isViewDisplayed = false
    private var isViewForciblyClosed = false
    private var initialPosition: CGPoint?
    // END

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(under parentView: UIView, configuration: Configuration) {
        self.configuration = configuration
        guard let sellingInfo = self.sellingInfo(state: viewModel.state) else {
            return
        }

        self.setupViews(info: sellingInfo,
                        parentView: parentView,
                        configuration: configuration)
    }

    func close() {
        self.animateIfNeeded(forceClose: true)
    }

    // MARK: Private

    private func setupViews(info: SellingInformerState.Info, parentView: UIView, configuration: Configuration) {
        // START: Selling Informer
        let sellingInformer = SellingInformer(
            title: info.title,
            buttonTitle: info.buttonTitle,
            closeAction: { [weak self] in
                self?.animateIfNeeded(forceClose: true)
            },
            targetAction: {
                configuration.targetAction()
            }
        )
        // END
        // START: Self container
        let viewContainer = self
        viewContainer.backgroundColor = .clear
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        // END
        // START: Hosting Controller
        let viewController = UIHostingController(rootView: sellingInformer)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.backgroundColor = .clear
        viewContainer.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 8),
            viewController.view.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: -8),
            viewController.view.heightAnchor.constraint(equalToConstant: 90),
            viewController.view.topAnchor.constraint(equalTo: viewContainer.topAnchor),
            viewController.view.centerXAnchor.constraint(equalTo: viewContainer.centerXAnchor)
        ])
        // END
        // START: Parent view adding
        parentView.addSubview(viewContainer)
        let compactConstrains = [viewContainer.heightAnchor.constraint(equalToConstant: 100 + configuration.bottomInset)]
        let regularConstrains = [viewContainer.heightAnchor.constraint(equalToConstant: 130 + configuration.bottomInset)]
        NSLayoutConstraint.activate([
            viewContainer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            viewContainer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            viewContainer.topAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        let hasSmallScreen = false
        if hasSmallScreen {
            NSLayoutConstraint.activate(compactConstrains)
        } else {
            NSLayoutConstraint.activate(regularConstrains)
        }
        // END
    }

    private func animateIfNeeded(scrollView: UIScrollView? = nil, forceClose: Bool = false) {
        // START: Logic guard check
        let viewContainer = self
        guard let configuration = self.configuration,
              let scrollView = scrollView,
              !self.isViewForciblyClosed else {
            return
        }
        // END
        let sellingInfo = self.sellingInfo(state: self.viewModel.state)
        let schouldDisplay = self.schouldDisplayUI(scrollView: scrollView, screen: .main) && sellingInfo != nil
        let animationsInProgress = viewContainer.layer.animation(forKey: Constants.displayAnimationKey) != nil
        // Start: UI guard check
        guard !animationsInProgress || forceClose  else {
            return
        }
        // END
        // START: Animation
        if self.isViewDisplayed != schouldDisplay || forceClose {
            let schouldDisplayBottomToast = schouldDisplay && !forceClose
            let postionAnimationParams: (fromValue: CGFloat, toValue: CGFloat)
            let opacityAnimationParams: (fromValue: Float, toValue: Float)
            let initialPosition = self.initialPosition ?? viewContainer.layer.position
            if self.initialPosition == nil {
                self.initialPosition = initialPosition
            }
            if schouldDisplayBottomToast {
                opacityAnimationParams = (fromValue: Float(0), toValue: Float(1))
                postionAnimationParams = (fromValue: viewContainer.layer.position.y,
                                          toValue: initialPosition.y - viewContainer.frame.size.height) } else {
                                            opacityAnimationParams = (fromValue: 1, toValue: 0)
                                            postionAnimationParams = (fromValue: viewContainer.layer.position.y,
                                                                      toValue: initialPosition.y)
                                          }
            viewContainer.layer.position.y = postionAnimationParams.toValue
            viewContainer.layer.opacity = opacityAnimationParams.toValue

            CATransaction.begin()
            // START: Background
            if viewContainer.layer.sublayers?.first(where: { $0.name == Constants.backgroundGradientKey }) == nil {
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = CGRect(origin: CGPoint(x: 0, y: configuration.bottomInset),
                                             size: CGSize(width: viewContainer.bounds.size.width,
                                                          height: viewContainer.bounds.size.height - configuration.bottomInset
                                             ))
                gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.45).cgColor, UIColor.black.cgColor]
                gradientLayer.locations = [0.0, 0.35, 0.45, 1.0]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.name = Constants.backgroundGradientKey
                if let topLayer = viewContainer.layer.sublayers?.first {
                    viewContainer.layer.insertSublayer(gradientLayer, below: topLayer)
                    viewContainer.layer.masksToBounds = false
                }
            }
            // END
            let translationAnimation = CABasicAnimation(keyPath: "position.y")
            translationAnimation.fromValue = postionAnimationParams.fromValue
            translationAnimation.toValue = postionAnimationParams.toValue
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = opacityAnimationParams.fromValue
            opacityAnimation.toValue = opacityAnimationParams.toValue

            let group = CAAnimationGroup()
            group.duration = 0.2
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.animations = [translationAnimation, opacityAnimation]

            viewContainer.layer.add(group, forKey: Constants.displayAnimationKey)
            CATransaction.commit()
            self.isViewDisplayed = schouldDisplay
        }
        // END
        // START: Action
        if schouldDisplay, let sellingInfo = sellingInfo {
            configuration.displayAction(sellingInfo)
        }
        // END
        self.isViewForciblyClosed = forceClose
    }

    private func schouldDisplayUI(scrollView: UIScrollView, screen: UIScreen) -> Bool {
        let scrollPosition = scrollView.contentOffset.y
        let screenHeight = screen.bounds.size.height
        return (scrollPosition > 2 * screenHeight && scrollPosition < 6 * screenHeight)
    }

    private func sellingInfo(state: SellingInformerState) -> SellingInformerState.Info? {
        switch viewModel.state {
        case let .userUnpaidCohort15to30(info),
             let .userUnpaidCohort30to90(info),
             let .userUnpaidCohort90Plus(info),
             let .userCancelled(info),
             let .customerCancelled(info):
            return info
        default:
            return nil
        }
    }

}

extension SellingInformerView {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.animateIfNeeded(scrollView: scrollView)
    }

    func willDisplay(message: SellingInformerFeedMessage) {
        self.viewModel.update(message: message)
    }

}
