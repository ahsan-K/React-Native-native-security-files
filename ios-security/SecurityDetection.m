#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SecurityDetection, NSObject)

// MARK: - Frida detection
RCT_EXTERN_METHOD(isFridaDetected:(RCTPromiseResolveBlock)resolve
                         rejecter:(RCTPromiseRejectBlock)reject)

@end
