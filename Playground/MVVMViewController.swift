import UIKit
import WebKit

protocol ViewMovel {
  
}

protocol View: AnyObject {
 
  associatedtype ViewModel
  
  var viewModel: ViewModel { get set }
  
}

class MVVMViewController: UIViewController {

  
  
}
