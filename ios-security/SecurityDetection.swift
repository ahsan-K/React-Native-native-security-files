import Foundation
import Foundation
import UIKit
import React

@objc(SecurityDetection)
class SecurityDetection: NSObject {
  @objc
  func isFridaDetected(_ resolve: RCTPromiseResolveBlock,
                       rejecter reject: RCTPromiseRejectBlock) {
      
      let suspiciousLibs = [
          "frida", "frida-gadget", "libfrida", "re.frida.server"
      ]

      for i in 0..<_dyld_image_count() {
          if let name = _dyld_get_image_name(i) {
              let lib = String(cString: name).lowercased()
              if suspiciousLibs.contains(where: { lib.contains($0) }) {
                  resolve(true)
                  return
              }
          }
      }
      resolve(false)
  }
}
