package com.coinbase.wallet.http.models

import java.net.URL

/**
 * Represents base URL for services
 *
 * @property Base url for service
 */
data class HTTPService(val url: URL) {
    companion object
}
