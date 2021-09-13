//
//  main.swift
//  macOSPlayground
//
//  Created by Amin Benarieb on 04.09.2021.
//

import Foundation

Some().doSomething("in code")
print("exit")
while(true){}

@objc class Some: NSObject {
 
  @objc dynamic func doSomething(_ parametr: String) {
    print("doSomething \(parametr)")
  }
  
  @objc dynamic func doSomethingElse(){
    print("doSomethingElse")
  }
  
}
  

