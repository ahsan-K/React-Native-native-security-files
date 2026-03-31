package com.projectname.security

import android.os.Build
import java.io.File

object EmulatorDetection {

    @JvmStatic
    fun isRunningOnEmulator(): Boolean {
        val model = Build.MODEL ?: ""
        val manufacturer = Build.MANUFACTURER ?: ""
        val brand = Build.BRAND ?: ""
        val device = Build.DEVICE ?: ""
        val hardware = Build.HARDWARE ?: ""
        val product = Build.PRODUCT ?: ""
        val fingerprint = Build.FINGERPRINT ?: ""

        // 1) Fingerprint
        if (fingerprint.startsWith("generic", ignoreCase = true) ||
            fingerprint.lowercase().contains("virtual"))
            return true

        // 2) Model patterns
        if (model.contains("Emulator", ignoreCase = true) ||
            model.contains("Android SDK built for x86", ignoreCase = true))
            return true

        // 3) Manufacturer / brand / device combos
        if (manufacturer.equals("Google", ignoreCase = true) &&
            (brand.startsWith("generic", ignoreCase = true) ||
             device.startsWith("generic", ignoreCase = true)))
            return true

        if (manufacturer.contains("Genymotion", ignoreCase = true))
            return true

        // 4) Hardware flags
        if (hardware.equals("goldfish", ignoreCase = true) ||
            hardware.equals("ranchu", ignoreCase = true) ||
            hardware.equals("qemu", ignoreCase = true))
            return true

        // 5) Product name
        if (product.contains("sdk", ignoreCase = true) ||
            product.contains("emulator", ignoreCase = true) ||
            product.contains("simulator", ignoreCase = true))
            return true

        // 6) Serial number check (with try/catch)
        // Optional serial check (safe for Android 10+)
        val serialSuspicious = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                false // cannot read serial, skip check
            } else {
                val serial = Build.getSerial()
                serial.isNullOrEmpty() || serial.equals("unknown", true)
            }
        } catch (_: Exception) {
            false
        }
        if (serialSuspicious) return true

        // 7) Emulator-specific files
        val files = arrayOf(
            "/dev/qemu_pipe",
            "/dev/socket/qemud",
            "/system/lib/libc_malloc_debug_qemu.so",
            "/sys/qemu_trace",
            "/system/bin/qemu-props"
        )
        if (files.any { File(it).exists() }) return true

        return false
    }

    @JvmStatic
    fun isDebugging(): Boolean {
        return android.os.Debug.isDebuggerConnected() ||
               android.os.Debug.waitingForDebugger()
    }

}
