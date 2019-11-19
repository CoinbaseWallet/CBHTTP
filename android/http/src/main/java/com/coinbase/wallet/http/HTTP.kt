package com.coinbase.wallet.http

import com.coinbase.wallet.core.extensions.Strings
import com.coinbase.wallet.core.extensions.empty
import com.coinbase.wallet.core.util.JSON
import com.coinbase.wallet.http.extensions.appendingPathComponent
import com.coinbase.wallet.http.extensions.asHTTPResponse
import com.coinbase.wallet.http.models.Credentials
import com.coinbase.wallet.http.models.HTTPResponse
import com.coinbase.wallet.http.models.HTTPService
import com.coinbase.wallet.http.models.QueryString
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import java.io.IOException
import java.net.URL
import java.util.concurrent.TimeUnit

object HTTP {
    const val kDefaultTimeout: Long = 15
    private val kJSONContentType = MediaType.parse("application/json; charset=utf-8")

    @PublishedApi
    internal val client = OkHttpClient.Builder()
        .connectTimeout(kDefaultTimeout, TimeUnit.SECONDS)
        .build()

    @PublishedApi
    internal val schedulers = Schedulers.io()

    /**
     * Creates a HTTP Get operation and parses result using the specified clazz
     *
     * @param service The service for the API call. Used as baseURL
     * @param path The relative path for the API call. Appended to the baseURL.
     * @param credentials HTTP basic auth credentials
     * @param parameters A dictionary with params to be sent as query params
     * @param headers A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
     * @param clazz Clazz model used to parse json to given model
     *
     * @return An instance of Single<T>
     */
    inline fun <reified T : Any> get(
        service: HTTPService,
        path: String,
        credentials: Credentials? = null,
        parameters: Map<String, String>? = null,
        headers: Map<String, String>? = null
    ): Single<HTTPResponse<T>> {
        var builder = Request.Builder()
        var url = service.url.appendingPathComponent(path)

        headers?.let { headers -> headers.forEach { builder = builder.header(it.key, it.value) } }
        credentials?.basicAuth?.let { builder = builder.header("Authorization", it) }

        if (parameters != null) {
            val queryString = QueryString()
            parameters.forEach { queryString.add(it.key, it.value) }
            url = URL("$url?$queryString")
        }

        val request = builder.url(url).build()

        return Single
            .create<HTTPResponse<T>> { emitter ->
                client.newCall(request).enqueue(object : Callback {
                    override fun onFailure(call: Call, e: IOException) {
                        emitter.onError(e)
                    }

                    override fun onResponse(call: Call, response: Response) {
                        emitter.onSuccess(response.asHTTPResponse())
                    }
                })
            }
            .subscribeOn(schedulers)
    }

    /**
     * Creates a HTTP Post operation and parses result using the specified clazz
     *
     * @param service The service for the API call. Used as baseURL
     * @param path The relative path for the API call. Appended to the baseURL.
     * @param credentials HTTP basic auth credentials
     * @param parameters A JSON object, to be sent as the HTTP body data.
     * @param headers A [String: String] dictionary mapping HTTP header field names to values. Defaults to nil.
     * @param clazz Clazz model used to parse json to given model
     *
     * @return An instance of Single<T>
     */
    inline fun <reified T : Any> post(
        service: HTTPService,
        path: String,
        credentials: Credentials? = null,
        parameters: Map<String, Any>? = null,
        headers: Map<String, String>? = null
    ): Single<HTTPResponse<T>> {
        val request = buildPostRequest(
            service = service,
            path = path,
            credentials = credentials,
            parameters = parameters,
            headers = headers
        )

        return Single
            .create<HTTPResponse<T>> { emitter ->
                client.newCall(request).enqueue(object : Callback {
                    override fun onFailure(call: Call, e: IOException) {
                        emitter.onError(e)
                    }

                    override fun onResponse(call: Call, response: Response) {
                        emitter.onSuccess(response.asHTTPResponse())
                    }
                })
            }
            .subscribeOn(schedulers)
    }

    // Helpers

    @PublishedApi
    internal fun buildPostRequest(
        service: HTTPService,
        path: String,
        credentials: Credentials?,
        parameters: Map<String, Any>?,
        headers: Map<String, String>?
    ): Request {
        var builder = Request.Builder()
        val url = service.url.appendingPathComponent(path)

        headers?.let { headers -> headers.forEach { builder = builder.header(it.key, it.value) } }
        credentials?.basicAuth?.let { builder = builder.header("Authorization", it) }

        val requestBody = if (parameters != null) {
            val jsonString = JSON.toJsonString(parameters)
            RequestBody.create(kJSONContentType, jsonString)
        } else {
            RequestBody.create(null, Strings.empty)
        }

        builder = builder.post(requestBody)

        return builder.url(url).build()
    }
}
