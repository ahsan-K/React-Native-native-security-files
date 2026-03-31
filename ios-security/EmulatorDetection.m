#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>

#pragma mark - Native checks

static BOOL isSimulator(void) {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

static BOOL isDebugged(void) {
    int name[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    struct kinfo_proc info;
    size_t size = sizeof(info);
    memset(&info, 0, sizeof(info));
    sysctl(name, 4, &info, &size, NULL, 0);
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

static BOOL isJailbroken(void) {
#if TARGET_OS_SIMULATOR
    return YES;
#endif

    NSArray *paths = @[
        @"/Applications/Cydia.app",
        @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/bin/bash",
        @"/usr/sbin/sshd",
        @"/etc/apt",
        @"/private/var/lib/apt/"
    ];

    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *p in paths) {
        if ([fm fileExistsAtPath:p]) return YES;
    }

    NSError *err = nil;
    NSString *testPath = @"/private/jb_test.txt";
    [@"test" writeToFile:testPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err == nil) {
        [fm removeItemAtPath:testPath error:nil];
        return YES;
    }

    return NO;
}

static BOOL isFridaDetected(void) {
    NSArray *keywords = @[
        @"frida",
        @"frida-gadget",
        @"libfrida",
        @"gum-js-loop",
        @"re.frida",
        @"linjector"
    ];

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *cname = _dyld_get_image_name(i);
        if (!cname) continue;

        NSString *name = [[NSString alloc] initWithUTF8String:cname];
        NSString *lower = name.lowercaseString;

        for (NSString *k in keywords) {
            if ([lower containsString:k]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - AUTO EXECUTION (NO AppDelegate)

__attribute__((constructor))
static void native_security_gate(void) {
#if DEBUG
    return;
#endif

    if (isSimulator() ||
        isDebugged() ||
        isJailbroken() ||
        isFridaDetected()) {

        dispatch_async(dispatch_get_main_queue(), ^{
            exit(0);
        });
    }
}
