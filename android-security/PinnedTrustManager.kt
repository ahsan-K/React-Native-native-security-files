package com.projectname.security

import android.util.Base64
import java.security.MessageDigest
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import javax.net.ssl.X509TrustManager

class PinnedTrustManager(
    private val defaultTm: X509TrustManager
) : X509TrustManager {

    // Domains that must be pinned
    private val allowedDomains = setOf(
        "kamilpay.com",
        "uat.kamilpay.com",
        "staging.kamilpay.com"
    )

    override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {
        defaultTm.checkClientTrusted(chain, authType)
    }

    override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {
        // Normal system trust check
        defaultTm.checkServerTrusted(chain, authType)

        if (chain.isEmpty()) {
            throw CertificateException("Empty server certificate chain")
        }

        val leafCert = chain[0]

        // Check domain is allowed for pinning
        if (!shouldPinCertificate(leafCert)) {
            // → External domains, Firebase, Google, etc... allow
            return
        }

        // Compute SHA-256 public key hash (Base64)
        val pubKeyBytes = leafCert.publicKey.encoded
        val digest = MessageDigest.getInstance("SHA-256").digest(pubKeyBytes)
        val base64 = Base64.encodeToString(digest, Base64.NO_WRAP)

        android.util.Log.e("PINNING", "Runtime Server Hash = $base64")

        // Compare using NDK
        val ok = NativeIntegrity.verifyPublicKeyHash(base64)

        android.util.Log.e("PINNING", "Native Match = $ok")

        if (!ok) {
            android.util.Log.e("PINNING", "Expected Hash = <stored_in_cpp>")
            throw CertificateException("Public key pin mismatch for allowed domain")
        }

    }

    override fun getAcceptedIssuers(): Array<X509Certificate> =
        defaultTm.acceptedIssuers

    private fun shouldPinCertificate(cert: X509Certificate): Boolean {
        val sanDomains = mutableListOf<String>()

        try {
            val altNames = cert.subjectAlternativeNames
            if (altNames != null) {
                for (entry in altNames) {
                    val type = entry[0] as Int  // 2 = DNS name
                    val value = entry[1] as String
                    if (type == 2) {
                        sanDomains.add(value.lowercase())
                    }
                }
            }
        } catch (_: Exception) {
            // ignore parsing issues; we'll just fall back to not pinning
        }

        // Check if any SAN domain matches our allowed domains (or subdomain)
        return sanDomains.any { dns ->
            allowedDomains.any { allowed ->
                dns.equals(allowed, ignoreCase = true) ||
                        dns.endsWith("." + allowed, ignoreCase = true)
            }
        }
    }
}
