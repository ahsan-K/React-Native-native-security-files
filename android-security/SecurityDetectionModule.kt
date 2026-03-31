package com.projectname.security

import com.facebook.react.bridge.*

class SecurityDetectionModule(
    private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "SecurityDetection"   // <-- must match JS module name
    }

    @ReactMethod
    fun isFridaDetected(promise: Promise) {
        try {
            val result = SecurityDetection.isFridaDetected()
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERR_FRIDA", e)
        }
    }

    @ReactMethod
    fun isXposedDetected(promise: Promise) {
        try {
            val result = SecurityDetection.isXposedDetected()
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERR_XPOSED", e)
        }
    }

    @ReactMethod
    fun isRooted(promise: Promise) {
        try {
            val result = SecurityDetection.isRooted()
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERR_ROOT", e)
        }
    }
}
