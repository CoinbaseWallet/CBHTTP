package com.coinbase.wallet.http.models

/**
 * The model object returned from HTTP methods
 *
 * @property body Decoded HTTP response body
 * @property headers HTTP response headers
 */
data class HTTPResponse<T : Any>(val body: T, val headers: Map<String, String>)
