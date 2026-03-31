package com.projectname.security

import com.facebook.react.modules.network.ReactCookieJarContainer
import okhttp3.OkHttpClient
import java.security.KeyStore
import javax.net.ssl.*

object PinnedHttpClientFactory {

    fun createPinnedOkHttpClient(): OkHttpClient {

        val tmFactory = TrustManagerFactory.getInstance(
            TrustManagerFactory.getDefaultAlgorithm()
        ).apply { init(null as KeyStore?) }

        val defaultTm = tmFactory.trustManagers
            .first { it is X509TrustManager } as X509TrustManager

        val pinnedTm = PinnedTrustManager(defaultTm)

        val sslContext = SSLContext.getInstance("TLS").apply {
            init(null, arrayOf<TrustManager>(pinnedTm), null)
        }

        return OkHttpClient.Builder()
            .sslSocketFactory(sslContext.socketFactory, pinnedTm)
            .cookieJar(ReactCookieJarContainer())
            .build()
    }
}
