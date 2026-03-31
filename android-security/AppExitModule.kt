package com.projectname.security

import android.app.Activity
import android.os.Process
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class AppExitModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "AppExit"

    @ReactMethod
    fun exitApp() {
        val activity: Activity? = currentActivity

        activity?.runOnUiThread {
            try {
                activity.finishAffinity()       // Close all activities
                activity.finish()              // Finish current activity
            } catch (_: Exception) {}

            try {
                Process.killProcess(Process.myPid())  // Kill process
            } catch (_: Exception) {}

            try {
                System.exit(0)                 // Final hard exit
            } catch (_: Exception) {}
        }
    }
}
