#include <jni.h>
#include <cstring>
#include <string.h>
#include <string>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <sys/system_properties.h>
#include <unistd.h>

// ============================================================
// 1) ANTI-FRIDA + ANTI-DEBUG (Native)
// ============================================================

static bool detectFridaMaps() {
    FILE* f = fopen("/proc/self/maps", "r");
    if (!f) return false;

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        // common frida/instrumentation keywords
        if (strstr(line, "frida") ||
                strstr(line, "re.frida.server") ||
                strstr(line, "frida-agent") ||
                strstr(line, "libfrida-gadget.so") ||
                strstr(line, "gum-js-loop") ||
                strstr(line, "gadget") ||
                strstr(line, "libfrida") ||
                strstr(line, "linjector") ||
                strstr(line, "xposed") ||
                strstr(line, "substrate")) {
                fclose(f);
                return true;
        }
    }
    fclose(f);
    return false;
}

static bool detectFridaPorts() {
    FILE* f = fopen("/proc/net/tcp", "r");
    if (!f) return false;

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        // 27042 -> 0x6992, 27043 -> 0x6993
        if (strstr(line, ":6992") || strstr(line, ":6993")) {
            fclose(f);
            return true;
        }
    }
    fclose(f);
    return false;
}

static bool detectFridaCmdline() {
    const char* keywords[] = {
             "frida",
            "frida-server",
            "re.frida.server",
            "re.frida",
            "frida-agent",
            "libfrida-gadget.so",
            "gum-js-loop"
    };

    FILE* p = popen("ps -A", "r");
    if (!p) return false;

    char line[256];
    while (fgets(line, sizeof(line), p)) {
        for (const char* k : keywords) {
            if (strstr(line, k)) {
                pclose(p);
                return true;
            }
        }
    }
    pclose(p);
    return false;
}

static bool detectDebuggerTracerPid() {
    FILE* f = fopen("/proc/self/status", "r");
    if (!f) return false;

    char line[256];
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "TracerPid:", 10) == 0) {
            int tracer = atoi(line + 10);
            fclose(f);
            return tracer != 0;
        }
    }
    fclose(f);
    return false;
}

// ============================================================
// 2) DETECT EMULATOR (Native)
// ============================================================
static bool fileExists(const char* path) {
    return (access(path, F_OK) == 0);
}

static std::string getSystemProp(const char* key) {
    char value[PROP_VALUE_MAX] = {0};
    __system_property_get(key, value);
    return std::string(value);
}

static bool contains(const std::string& s, const char* needle) {
    return s.find(needle) != std::string::npos;
}

static bool detectEmulatorNative() {
    // 1) QEMU pipes / traces
    if (fileExists("/dev/qemu_pipe")) return true;
    if (fileExists("/dev/qemu_trace")) return true;

    // 2) Common emulator files
    if (fileExists("/system/lib/libc_malloc_debug_qemu.so")) return true;
    if (fileExists("/sys/qemu_trace")) return true;

    // 3) System properties heuristics
    std::string roKernelQemu = getSystemProp("ro.kernel.qemu");
    if (roKernelQemu == "1") return true;

    std::string roHardware = getSystemProp("ro.hardware");
    if (contains(roHardware, "goldfish") || contains(roHardware, "ranchu") || contains(roHardware, "vbox86"))
        return true;

    std::string roProduct = getSystemProp("ro.product.device");
    if (contains(roProduct, "generic") || contains(roProduct, "emulator") || contains(roProduct, "sdk"))
        return true;

    std::string roModel = getSystemProp("ro.product.model");
    if (contains(roModel, "Android SDK built for") || contains(roModel, "Emulator") || contains(roModel, "sdk_gphone"))
        return true;

    std::string roManufacturer = getSystemProp("ro.product.manufacturer");
    if (contains(roManufacturer, "Genymotion") || contains(roManufacturer, "unknown"))
        return true;

    std::string roBrand = getSystemProp("ro.product.brand");
    std::string roName  = getSystemProp("ro.product.name");
    if (contains(roBrand, "generic") || contains(roName, "generic"))
        return true;

    return false;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_projectname_security_NativeIntegrity_isEmulatorDetected(
        JNIEnv* /* env */,
        jclass /* clazz */) {
    return detectEmulatorNative() ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_projectname_security_NativeIntegrity_isEnvironmentClean(
        JNIEnv* /* env */,
        jclass /* clazz */) {

    if (detectEmulatorNative()) return JNI_FALSE;
    if (detectFridaMaps()) return JNI_FALSE;
    if (detectFridaPorts()) return JNI_FALSE;
    if (detectDebuggerTracerPid()) return JNI_FALSE;
    if (detectFridaCmdline()) return JNI_FALSE;

    return JNI_TRUE;
}
