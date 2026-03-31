import Foundation
import UIKit
import React

@objc(AppExit)
class AppExit: NSObject {

  @objc
  func exitApp() {
    DispatchQueue.main.async {
      exit(0)
    }
  }
}
