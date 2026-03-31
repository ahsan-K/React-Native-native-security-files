package com.projectname.security

import com.facebook.react.bridge.*

class EmulatorDetectionModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "EmulatorDetection"

    @ReactMethod
    fun isEmulator(promise: Promise) {
        try {
            val result = EmulatorDetection.isRunningOnEmulator()
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERR_EMULATOR", e)
        }
    }

    @ReactMethod
    fun isDebugging(promise: Promise) {
        try {
            val result = EmulatorDetection.isDebugging()
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERR_DEBUGGING", e)
        }
    }

}
