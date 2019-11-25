import UIKit
import WebKit
import WKWebViewJavascriptBridge

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var inputTextField: UITextField!
    var bridge: WKWebViewJavascriptBridge!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup
        let points = [Int]((0...10)).map { CGPoint(x: $0, y: $0*$0) }
        let HTMLString = self.html(points: points)
        DispatchQueue.main.async {
            self.webView.loadHTMLString(HTMLString, baseURL: nil)
        }

        // Bridge
        bridge = WKWebViewJavascriptBridge(webView: webView)
        bridge.register(handlerName: "testiOSCallback") { (parameters, callback) in
            print("testiOSCallback called: \(String(describing: parameters))")
            callback?("Response from testiOSCallback")
        }
    }

    private func html(points: [CGPoint]) -> String {
        let path = Bundle.main.path(forResource: "htmlGraph", ofType: "html")!
        let html = try! String(contentsOfFile: path)
        let xs = points.map { "\($0.x)" }.joined(separator: ",")
        let ys = points.map { "\($0.y)" }.joined(separator: ",")
        return String(format: html,
                      "[\(xs)]",
                      "[\(ys)]")
    }

    @IBAction func applyAction(_ sender: Any) {
        self.view.endEditing(true)
        bridge.call(handlerName: "testJavascriptHandler", data: ["input": inputTextField.text ?? ""]) { response in
            print("Response from testiOSCallback: \(String(describing: response))")
        }
    }


}

