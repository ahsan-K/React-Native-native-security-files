# 🔐 React Native Security Integration

![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)
![React
Native](https://img.shields.io/badge/React%20Native-Supported-61dafb)
![Security](https://img.shields.io/badge/Security-SSL%20Pinning%20%7C%20Anti--Tamper-red)
![License](https://img.shields.io/badge/license-MIT-green)

> 🚀 A complete security layer for React Native apps including SSL
> Pinning, Signature Validation, Emulator Detection, Anti-Frida &
> Environment Checks

------------------------------------------------------------------------

## ✨ Features

-   🔒 SSL Pinning
-   🛡️ App Signature Verification
-   🤖 Emulator Detection
-   🧪 Anti-Frida Protection
-   🚫 Root / Tamper Detection
-   ⚡ Native + JS Bridge

------------------------------------------------------------------------

## 📱 Android Setup

### Folder Setup

android-security → security\
android-native-security → security-native

### Gradle

implementation project(":security-native")

### NDK

ndk { abiFilters "armeabi-v7a", "arm64-v8a" }

### Security Check

if (!BuildConfig.DEBUG) { // checks here }

------------------------------------------------------------------------

## 🍎 iOS Setup

-   Rename ios-security → security
-   Place inside ios/
-   Update TeamID & BundleID

------------------------------------------------------------------------

## 🟨 JavaScript

import Security from "./src/utils/security";

Security.runSecurityCheck();

------------------------------------------------------------------------

## ⚠️ Notes

-   Update SHA256 & keystore
-   Use real SSL cert
-   Test on release build

------------------------------------------------------------------------

## 📄 License

MIT License © 2026
