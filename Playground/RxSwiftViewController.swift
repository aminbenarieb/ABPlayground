import Foundation
import UIKit
import RxSwift

class RxSwiftViewController: UIViewController {
    
    private let behaviorSubject = BehaviorSubject<Int>(value: 0)
    private var disposeBag = DisposeBag()
    private var textView: UITextView?
    
    override func viewDidLoad() {
        self.view.backgroundColor = .white
        let textView = UITextView(frame: self.view.bounds)
        textView.backgroundColor = .clear
        textView.textColor = .black
        self.view.addSubview(textView)
        self.textView = textView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        behaviorSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                guard let textView = self?.textView else { return }
                textView.text = textView.text + "behaviorSubject event \(value)\n"
            print("behaviorSubject event \(value)")
        })
        .disposed(by: self.disposeBag)
        for _ in (0..<10) {
            self.behaviorSubject.onNext(try! self.behaviorSubject.value() + 1)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.disposeBag = DisposeBag()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for _ in (0..<10) {
            self.behaviorSubject.onNext(try! self.behaviorSubject.value() + 1)
        }
    }
    
}
