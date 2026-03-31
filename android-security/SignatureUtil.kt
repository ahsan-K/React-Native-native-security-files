package com.projectname.security

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

object SignatureUtil {

    fun getAppSignatureSha256Hex(context: Context): String {
        val packageName = context.packageName
        val pm = context.packageManager

        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo!!.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }

        val certBytes = signatures?.get(0)?.toByteArray()
        val digest = MessageDigest.getInstance("SHA-256").digest(certBytes)

        // lowercase hex (important!)
        return digest.joinToString("") { "%02x".format(it) }
    }
}
