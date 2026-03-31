import Foundation
import UIKit
import React

@objc(EmulatorDetection)
class EmulatorDetection: NSObject {

  @objc
  func isEmulator(_ resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {

    #if TARGET_IPHONE_SIMULATOR
      resolve(true)   // Simulator = Emulator
      return
    #endif

    resolve(Self.isJailbroken())
  }

  @objc
  func isDebugging(_ resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {

      var name = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
      var info = kinfo_proc()
      var size = MemoryLayout<kinfo_proc>.stride

      let sysctlResult = sysctl(&name, UInt32(name.count), &info, &size, nil, 0)

      let isDebugged = (sysctlResult == 0) && ((info.kp_proc.p_flag & P_TRACED) != 0)

      resolve(isDebugged)
  }
  
  static func isJailbroken() -> Bool {
    return hasSuspiciousFiles() ||
           canOpenCydia() ||
           canWriteOutsideSandbox()
  }

  private static func hasSuspiciousFiles() -> Bool {
    let paths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt"
    ]
    return paths.contains { FileManager.default.fileExists(atPath: $0) }
  }

  private static func canOpenCydia() -> Bool {
    guard let url = URL(string: "cydia://package/com.example") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private static func canWriteOutsideSandbox() -> Bool {
    let test = "/private/jb_test.txt"
    do {
      try "test".write(toFile: test, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: test)
      return true
    } catch {
      return false
    }
  }
}
