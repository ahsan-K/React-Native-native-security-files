#include <jni.h>
#include <cstring>
#include <string.h>
#include <string>
#include <vector>
#include <cstdio>
#include <cstdlib>

// ------------------------------------------------------------
// CONSTANT-TIME compare (case-sensitive) for pins/base64
// ------------------------------------------------------------
static bool constantTimeEquals(const char* a, const char* b) {
    if (!a || !b) return false;

    size_t lenA = strlen(a);
    size_t lenB = strlen(b);
    if (lenA != lenB) return false;

    volatile unsigned char diff = 0;
    for (size_t i = 0; i < lenA; ++i) {
        diff |= (unsigned char)(a[i] ^ b[i]);
    }
    return diff == 0;
}

// ------------------------------------------------------------
// CONSTANT-TIME compare (case-insensitive) for HEX signatures
// ------------------------------------------------------------
static bool constantTimeEqualsIgnoreCase(const char* a, const char* b) {
    if (!a || !b) return false;

    size_t lenA = strlen(a);
    size_t lenB = strlen(b);
    if (lenA != lenB) return false;

    volatile unsigned char diff = 0;
    for (size_t i = 0; i < lenA; ++i) {
        unsigned char ca = (unsigned char)a[i];
        unsigned char cb = (unsigned char)b[i];

        // tolower (ASCII)
        if (ca >= 'A' && ca <= 'Z') ca = (unsigned char)(ca - 'A' + 'a');
        if (cb >= 'A' && cb <= 'Z') cb = (unsigned char)(cb - 'A' + 'a');

        diff |= (unsigned char)(ca ^ cb);
    }
    return diff == 0;
}

// ------------------------------------------------------------
// XOR decode helper (obfuscation for pins)
// ------------------------------------------------------------
static std::string xorDecode(const uint8_t* data, size_t len, uint8_t key) {
    std::string out;
    out.resize(len);
    for (size_t i = 0; i < len; ++i) {
        out[i] = (char)(data[i] ^ key);
    }
    return out;
}

// ============================================================
// 1) SSL PINNING (Native)
// ============================================================
// Stored XOR-obfuscated to reduce static extraction.
static const uint8_t PIN_KEY = 0x5A;

static const uint8_t PIN1_XOR[] = {
    0x2A, 0x4F, 0x19, 0x73, 0x0C, 0x55, 0x61, 0x2D,
    0x11, 0x3B, 0x6E, 0x08, 0x47, 0x22, 0x39, 0x5C,
    0x14, 0x6A, 0x27, 0x3E, 0x1B, 0x45, 0x20, 0x0F,
    0x6D, 0x33, 0x10, 0x5A, 0x64, 0x09, 0x71, 0x2C,
    0x58, 0x3A, 0x6F, 0x18, 0x21, 0x07, 0x0E, 0x49,
    0x3D, 0x12, 0x66, 0x2B
};

static const uint8_t PIN2_XOR[] = {
    0x3C, 0x17, 0x2E, 0x41, 0x6B, 0x0D, 0x25, 0x19,
    0x5F, 0x62, 0x33, 0x28, 0x1A, 0x3D, 0x04, 0x2F,
    0x37, 0x15, 0x06, 0x1D, 0x2B, 0x30, 0x6C, 0x21,
    0x44, 0x16, 0x1F, 0x2A, 0x1C, 0x69, 0x35, 0x08,
    0x3A, 0x0B, 0x09, 0x63, 0x05, 0x1E, 0x2C, 0x3F,
    0x72, 0x1A, 0x6D, 0x60
};

static bool isPinnedHashAllowed(const char* serverHashBase64) {

    std::string pin1 = xorDecode(PIN1_XOR, sizeof(PIN1_XOR), PIN_KEY);
    std::string pin2 = xorDecode(PIN2_XOR, sizeof(PIN2_XOR), PIN_KEY);

    if (constantTimeEquals(serverHashBase64, pin1.c_str())) {
        return true;
    }

    if (constantTimeEquals(serverHashBase64, pin2.c_str())) {
        return true;
    }

    return false;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_projectname_security_NativeIntegrity_verifyPublicKeyHash(
        JNIEnv* env,
        jclass /* clazz */,
        jstring serverHash_) {

    if (serverHash_ == nullptr) return JNI_FALSE;

    const char* serverHash = env->GetStringUTFChars(serverHash_, nullptr);
    bool ok = isPinnedHashAllowed(serverHash);
    env->ReleaseStringUTFChars(serverHash_, serverHash);

    return ok ? JNI_TRUE : JNI_FALSE;
}


// Release / Upload keystore
static const char* SIG_RELEASE =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

// Google Play Internal App Sharing
static const char* SIG_INTERNAL_APP_SHARING =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

// Google Play App Signing key
static const char* SIG_PLAY_SIGNING =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_projectname_security_NativeIntegrity_isAppSignatureValid(
        JNIEnv* env,
        jclass /* clazz */,
        jstring sigHex_) {

    if (sigHex_ == nullptr) {
        return JNI_FALSE;
    }

    const char* sigHex = env->GetStringUTFChars(sigHex_, nullptr);

    bool match =
            constantTimeEqualsIgnoreCase(sigHex, SIG_RELEASE) ||
            // constantTimeEqualsIgnoreCase(sigHex, SIG_INTERNAL_APP_SHARING) || removed for now
            constantTimeEqualsIgnoreCase(sigHex, SIG_PLAY_SIGNING);

    env->ReleaseStringUTFChars(sigHex_, sigHex);

    return match ? JNI_TRUE : JNI_FALSE;
}
