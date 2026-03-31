import { NativeModules, Platform } from "react-native";

const { EmulatorDetection, ActivityStarter, AppExit, SecurityDetection } = NativeModules;

/**
 * Detect Emulator (Android + iOS)
 */
export const isEmulator = async () => {
    try {
        const result = await EmulatorDetection?.isEmulator?.();
        return !!result;
    } catch (e) {
        console.log("Emulator check error:", e);
        return false;
    }
};

/**
 * Debugger Detection (Android + iOS)
 */
export const isDebugging = async () => {
    try {
        const result = await EmulatorDetection?.isDebugging?.();
        return !!result;
    } catch (e) {
        console.log("Debug check error:", e);
        return false;
    }
};

/**
 * Frida Detection (Android + iOS)
 */
export const isFridaDetected = async () => {
    try {
        const result = await SecurityDetection?.isFridaDetected?.();
        return !!result;
    } catch (e) {
        console.log("Frida detection error:", e);
        return false;
    }
};

/**
 * Xposed Detection
 */
export const isXposedDetected = async () => {
    try {
        if (Platform.OS !== "android") return false;
        const result = await SecurityDetection?.isXposedDetected?.();
        return !!result;
    } catch (e) {
        console.log("Xposed detection error:", e);
        return false;
    }
};

/**
 * Root Detection
 */
export const isRooted = async () => {
    try {
        if (Platform.OS !== "android") return false;
        const result = await SecurityDetection?.isRooted?.();
        return !!result;
    } catch (e) {
        console.log("Root detection error:", e);
        return false;
    }
};

/**
 * Prevent screenshot & screen recording
 */
export const setSecureFlag = (enable = true) => {
    try {
        ActivityStarter?.setSecureFlag?.(enable);
    } catch (e) {
        console.log("FLAG_SECURE error:", e);
    }
};

/**
 * Kill application (Android + iOS)
 */
export const killApp = () => {
    try {
        AppExit?.exitApp?.();
    } catch (e) {
        console.log("Kill app error:", e);
    }
};

/**
 * FULL SECURITY SUITE — CALL ON APP STARTUP
 */
export const runSecurityCheck = async () => {
    const emulator = await isEmulator();
    const debugging = await isDebugging();
    const frida = await isFridaDetected();
    const xposed = await isXposedDetected();
    // const rooted = await isRooted();

    console.log("Security Check Results:", {
        emulator,
        debugging,
        frida,
        xposed,
        // rooted,
    });

    const unsafe =
        emulator ||
        debugging ||
        frida ||
        xposed
        // || rooted
    ;

    if (unsafe) {
        if (!__DEV__) {
            setTimeout(() => killApp(), 200);
        } else {
            alert("Security violation detected — app would close in production!");
        }
        return false;
    }

    if (!__DEV__) setSecureFlag(true);

    return true;
};

export default {
    isEmulator,
    isDebugging,
    isFridaDetected,
    isXposedDetected,
    isRooted,
    setSecureFlag,
    killApp,
    runSecurityCheck,
};
