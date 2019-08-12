package com.coinbase.wallet.http.models

import java.io.UnsupportedEncodingException
import java.net.URLEncoder

/**
 * GET query params helper
 */
class QueryString {
    private var query = ""

    fun add(name: String, value: String) {
        query += "&"
        encode(name, value)
    }

    private fun encode(name: String, value: String) {
        try {
            query += URLEncoder.encode(name, "UTF-8")
            query += "="
            query += URLEncoder.encode(value, "UTF-8")
        } catch (ex: UnsupportedEncodingException) {
            throw RuntimeException("Broken VM does not support UTF-8")
        }
    }

    override fun toString(): String = query
}
