// NativeSecurityGate.m
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <unistd.h>

// ------------------------------------------------------
// CONFIG
// ------------------------------------------------------
#define NSG_ENABLE_IN_DEBUG 0          // 0 = DEBUG me gate off, 1 = DEBUG me bhi ON
#define NSG_BLOCK_SIMULATOR 0          // 1 = simulator block (only when gate enabled)
#define NSG_USE_PTRACE_DENY 0          // 1 = enable anti-debug ptrace (optional)

// ------------------------------------------------------
// Helpers
// ------------------------------------------------------
static inline void NSG_KillFast(void) {
    // exit(0) silent; abort() crash log
    // exit(0);
    abort();
}

static inline void NSG_KillOnMain(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSG_KillFast();
    });
}

static BOOL NSG_fileExists(const char *path) {
    return (access(path, F_OK) == 0);
}

@interface NativeSecurityGate : NSObject
+ (BOOL)isValid;
@end

@implementation NativeSecurityGate

+ (BOOL)isValid {
    // Always validate when gate is enabled (debug/release decision is handled in constructor)
    return [self checkBundleID] && [self checkTeamID];
}

+ (BOOL)checkBundleID {
    NSString *expectedBundleID = @"com.kamelpay";
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    return [bundleID isEqualToString:expectedBundleID];
}

+ (BOOL)checkTeamID {
    // ⚠️ App Store builds: embedded.mobileprovision often missing.
    // To avoid bricking, fail-open if not present.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    if (!path) return YES;

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return YES;

    NSString *content = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if (!content.length) return YES;

    NSRange start = [content rangeOfString:@"<?xml"];
    NSRange end   = [content rangeOfString:@"</plist>"];
    if (start.location == NSNotFound || end.location == NSNotFound) return YES;

    NSString *plistString =
    [content substringWithRange:NSMakeRange(start.location, end.location + end.length - start.location)];

    NSData *plistData = [plistString dataUsingEncoding:NSUTF8StringEncoding];
    if (!plistData) return YES;

    NSDictionary *plist =
    [NSPropertyListSerialization propertyListWithData:plistData options:0 format:nil error:nil];

    NSDictionary *entitlements = plist[@"Entitlements"];
    NSString *appID = entitlements[@"application-identifier"];
    if (!appID.length) return YES;

    NSString *teamID = [[appID componentsSeparatedByString:@"."] firstObject] ?: @"";
    NSString *expectedTeamID = @"94T5VS5SSY";

    return [teamID isEqualToString:expectedTeamID];
}

@end

#pragma mark - Runtime checks

static BOOL NSG_isDebugged_sysctl(void) {
    int name[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    struct kinfo_proc info;
    size_t size = sizeof(info);
    memset(&info, 0, sizeof(info));
    if (sysctl(name, 4, &info, &size, NULL, 0) != 0) return NO;
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

static void NSG_denyDebugger_ptrace(void) {
#if NSG_USE_PTRACE_DENY
    typedef int (*ptrace_ptr)(int, pid_t, caddr_t, int);
    ptrace_ptr ptrace_fn = (ptrace_ptr)dlsym(RTLD_DEFAULT, "ptrace");
    if (ptrace_fn) {
        // PT_DENY_ATTACH = 31
        ptrace_fn(31, 0, 0, 0);
    }
#endif
}

static BOOL NSG_isJailbroken(void) {
#if TARGET_OS_SIMULATOR
    return NO;
#endif

    const char *paths[] = {
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/",
        "/var/lib/cydia",
        "/bin/bash",
        "/usr/bin/ssh",
        "/usr/libexec/ssh-keysign",
        "/private/var/stash"
    };

    for (size_t i = 0; i < sizeof(paths)/sizeof(paths[0]); i++) {
        if (NSG_fileExists(paths[i])) return YES;
    }

    NSError *err = nil;
    NSString *testPath = @"/private/nsg_jb_test.txt";
    [@"x" writeToFile:testPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err == nil) {
        [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
        return YES;
    }

    char *dyld = getenv("DYLD_INSERT_LIBRARIES");
    if (dyld && strlen(dyld) > 0) return YES;

    return NO;
}

static BOOL NSG_isFridaDetected(void) {
    NSArray *keywords = @[
        @"frida",
        @"frida-gadget",
        @"frida-agent",
        @"libfrida",
        @"gum-js-loop",
        @"re.frida",
        @"linjector"
    ];

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *cname = _dyld_get_image_name(i);
        if (!cname) continue;
        NSString *lower = [[[NSString alloc] initWithUTF8String:cname] lowercaseString];
        for (NSString *k in keywords) {
            if ([lower containsString:k]) return YES;
        }
    }

    char *insert = getenv("DYLD_INSERT_LIBRARIES");
    if (insert && strlen(insert) > 0) return YES;

    return NO;
}

#pragma mark - Auto execution (NO AppDelegate)

__attribute__((constructor))
static void native_security_gate(void) {

#if DEBUG
    return; // 🚫 Debug scheme: skip ALL security checks
#endif

#if TARGET_OS_SIMULATOR
    if (NSG_BLOCK_SIMULATOR == 1) {
        NSG_KillOnMain();
        return;
    }
#endif

    // Optional anti-debug hardening early
    NSG_denyDebugger_ptrace();

    // Bundle / Team validation
    if (![NativeSecurityGate isValid]) {
        NSG_KillOnMain();
        return;
    }

    // Runtime checks
    if (NSG_isDebugged_sysctl() ||
        NSG_isJailbroken() ||
        NSG_isFridaDetected()) {
        NSG_KillOnMain();
        return;
    }
}
