package com.coinbase.wallet.http.extensions

import com.coinbase.wallet.core.util.JSON
import com.coinbase.wallet.http.exceptions.HTTPException
import com.coinbase.wallet.http.models.HTTPResponse
import okhttp3.Response
import timber.log.Timber

/**
 * Convert an okhttp response to a CBHTTP response
 */
inline fun <reified T : Any> Response.asHTTPResponse(): HTTPResponse<T> {
    val result = if (T::class.java == ByteArray::class.java) {
        (body()?.bytes() ?: ByteArray(0)) as T
    } else {
        val json = body()?.string() ?: throw HTTPException.UnableToDeserialize
        JSON.fromJsonString<T>(json) ?: throw HTTPException.UnableToDeserialize
    }

    val rspHeaders = headers()
    val headersMap = (0 until rspHeaders.size())
        .map { rspHeaders.name(it) to rspHeaders.value(it) }
        .toMap()

    return HTTPResponse(body = result, headers = headersMap)
}
