package com.projectname.security

import android.content.Context
import android.os.Build
import android.util.Base64
import java.io.File
import java.security.MessageDigest

object SecurityDetection {

    // -------------------------------------------------------------------------
    // 2) FRIDA DETECTION
    // -------------------------------------------------------------------------
    @JvmStatic
    fun isFridaDetected(): Boolean {
        // 1) Known frida server paths (cheap signal)
        val fridaFiles = arrayOf(
            "/data/local/tmp/frida-server",
            "/data/local/tmp/frida",
            "/data/local/tmp/re.frida.server",
            "/data/local/tmp/fridaserver",
            "/system/bin/frida",
            "/system/xbin/frida"
        )
        if (fridaFiles.any { File(it).exists() }) return true

        // 2) /proc/self/maps scan (strongest Java-side signal)
        if (scanSelfMapsForFrida()) return true

        // 3) Check default frida ports (heuristic)
        if (isFridaPortOpen()) return true

        // 4) Best-effort: scan other processes cmdline (may be restricted on newer Android)
        if (scanProcCmdlineForFrida()) return true

        return false
    }

    private fun scanSelfMapsForFrida(): Boolean {
        return try {
            val keywords = arrayOf(
                "frida", "gum-js-loop", "gadget", "libfrida", "frida-agent", "re.frida"
            )
            File("/proc/self/maps").useLines { lines ->
                lines.any { line ->
                    val l = line.lowercase()
                    keywords.any { k -> l.contains(k) }
                }
            }
        } catch (_: Throwable) {
            false
        }
    }

    private fun isFridaPortOpen(): Boolean {
        // Frida defaults: 27042 (server), 27043
        // /proc/net/tcp stores ports in HEX in little-ish formatting; we just search for ":6992" and ":6993"
        // 27042 -> 0x6992, 27043 -> 0x6993
        return try {
            val tcp = File("/proc/net/tcp")
            if (!tcp.exists()) return false
            val text = tcp.readText()
            text.contains(":6992", ignoreCase = true) || text.contains(":6993", ignoreCase = true)
        } catch (_: Throwable) {
            false
        }
    }

    private fun scanProcCmdlineForFrida(): Boolean {
        return try {
            val keywords = arrayOf("frida", "frida-server", "re.frida.server", "gum-js-loop")
            val procDir = File("/proc")
            val pids = procDir.listFiles()?.asSequence()
                ?.filter { it.isDirectory && it.name.all(Char::isDigit) }
                ?.take(128) // limit to avoid heavy scan
                ?: return false

            for (pidDir in pids) {
                val cmdline = File(pidDir, "cmdline")
                val content = try {
                    cmdline.readBytes().toString(Charsets.UTF_8).lowercase()
                } catch (_: Throwable) {
                    continue
                }
                if (keywords.any { content.contains(it) }) return true
            }
            false
        } catch (_: Throwable) {
            false
        }
    }

    // -------------------------------------------------------------------------
    // 3) XPOSED DETECTION
    // -------------------------------------------------------------------------
    @JvmStatic
    fun isXposedDetected(): Boolean {
        return try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            true
        } catch (_: Exception) {
            false
        }
    }


    // -------------------------------------------------------------------------
    // 4) MAGISK / ROOT DETECTION (OPTIONAL BUT RECOMMENDED)
    // -------------------------------------------------------------------------
    @JvmStatic
    fun isRooted(): Boolean {
        val rootFiles = arrayOf(
            "/system/app/Superuser.apk",
            "/system/xbin/su",
            "/system/bin/su",
            "/sbin/su",
            "/su/bin/su"
        )

        if (rootFiles.any { File(it).exists() }) return true

        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) return true

        return false
    }
}
