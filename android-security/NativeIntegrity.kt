package com.projectname.security

object NativeIntegrity {

    init {
        System.loadLibrary("sslpinning") // same .so used
    }

    @JvmStatic
    external fun isAppSignatureValid(sigHex: String): Boolean

    @JvmStatic
    external fun isEnvironmentClean(): Boolean

    @JvmStatic
    external fun verifyPublicKeyHash(serverHash: String): Boolean
}
