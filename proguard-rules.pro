# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

########################################
# General Settings
########################################
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn kotlin.**
-dontwarn kotlinx.**

########################################
# React Native (Required)
########################################
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }
-keep class com.facebook.jni.** { *; }
-keep class com.swmansion.reanimated.** { *; }
-keep class com.facebook.fresco.** { *; }
-keep class com.facebook.react.turbomodule.** { *; }
-keep class com.facebook.react.bridge.CatalystInstanceImpl { *; }
-keep class com.google.android.gms.location.** { *; }

########################################
# Main App Entry Points (projectname)
########################################
# Keep ONLY entry points — NOT the entire com.projectname package
-keep class com.projectname.MainApplication { *; }
-keep class com.projectname.MainActivity { *; }

# Keep your SSL pinning JNI bridge – VERY IMPORTANT
-keep class com.projectname.security.NativeIntegrity { *; }

# (Optional safety) – if you want ALL com.projectname safe for now:
-keep class com.projectname.** { *; }


########################################
# SVG / UI / Animations
########################################
-keep public class com.horcrux.svg.** { *; }

########################################
# OkHttp / Okio / Retrofit / Gson
########################################
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-dontwarn retrofit2.**

-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

########################################
# Hermes Engine
########################################
-keep class com.facebook.hermes.unicode.** { *; }
-dontwarn com.facebook.hermes.**

########################################
# AndroidX + Reflection Safety
########################################
-keep class androidx.** { *; }
-dontwarn androidx.**

########################################
# OneKYC SDK – Required for R8/ProGuard
########################################

# Keep OneKYC main package
-keep class com.onekyc.** { *; }
-dontwarn com.onekyc.**

# Keep OneKYC obfuscated internal packages (VERY IMPORTANT)
-keep class vo.** { *; }
-keep interface vo.** { *; }
-dontwarn vo.**

# Keep Retrofit models/interfaces
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-dontwarn retrofit2.**

# Keep annotations
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

# Keep Gson serialization fields
-keep class com.onekyc.** { *; }
-keepclassmembers class com.onekyc.** {
    @com.google.gson.annotations.SerializedName <fields>;
}

########################################
# Remove Android logs
########################################
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** w(...);
    public static *** v(...);
    public static *** i(...);
    public static *** e(...);
}

# Ignore typedef RetentionPolicy warnings
-dontwarn hot.ViewShot.**
-keep class hot.ViewShot.** { *; }

# --- RN core module required at bootstrap (New Arch) ---
-keep class com.facebook.react.modules.systeminfo.PlatformConstantsModule { *; }
-keep class com.facebook.react.modules.systeminfo.** { *; }


########################################
# React Native NEW ARCHITECTURE (FINAL FIX)
########################################

# FeatureFlags (C++ backed – VERY IMPORTANT)
-keep class com.facebook.react.internal.featureflags.** { *; }

# Fabric / Renderer / UIManager
-keep class com.facebook.react.fabric.** { *; }
-keep class com.facebook.react.uimanager.** { *; }
-keep class com.facebook.react.uimanager.events.** { *; }

# TurboModules core
-keep class com.facebook.react.turbomodule.core.** { *; }

# JNI / Hybrid classes used by New Arch
-keep class com.facebook.react.common.** { *; }
-keep class com.facebook.jni.** { *; }

# ReactHost / Bridgeless
-keep class com.facebook.react.ReactHost { *; }
-keep class com.facebook.react.runtime.** { *; }