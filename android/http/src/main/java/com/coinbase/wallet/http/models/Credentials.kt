package com.coinbase.wallet.http.models

import com.coinbase.wallet.core.extensions.base64EncodedString

/**
 * HTTP basic authentication credentials
 *
 * @property username HTTP basic authentication username
 * @property password HTTP basic authentication password
 */
data class Credentials(val username: String, val password: String) {
    /**
     * Properly encoded and formatted HTTP basic authentication header value
     */
    val basicAuth: String?
        get() {
            val credentialString = "$username:$password"
            val data = credentialString.toByteArray(Charsets.UTF_8)

            return "Basic ${data.base64EncodedString()}"
        }

    companion object
}
