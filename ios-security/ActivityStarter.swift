import Foundation
import UIKit
import React

@objc(ActivityStarter)
class ActivityStarter: NSObject {

  private var overlay: UIView?

  @objc
  func setSecureFlag(_ enable: Bool) {
    DispatchQueue.main.async {
      if enable {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(self.onCaptureChange),
          name: UIScreen.capturedDidChangeNotification,
          object: nil
        )
        self.handleCurrentState()
      } else {
        NotificationCenter.default.removeObserver(self)
        self.removeOverlay()
      }
    }
  }

  @objc private func onCaptureChange() {
    handleCurrentState()
  }

  private func handleCurrentState() {
    let isCaptured = UIScreen.main.isCaptured
    if isCaptured {
      addOverlay()
    } else {
      removeOverlay()
    }
  }

  private func addOverlay() {
    guard let window = getActiveWindow() else { return }

    if overlay != nil { return }

    let blackView = UIView(frame: window.bounds)
    blackView.backgroundColor = .black
    blackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blackView.tag = 99999

    window.addSubview(blackView)
    overlay = blackView
  }

  private func removeOverlay() {
    overlay?.removeFromSuperview()
    overlay = nil
  }

  private func getActiveWindow() -> UIWindow? {
    // iOS 15+ correct approach
    return UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
