package com.coinbase.wallet.http.websocket

import com.coinbase.wallet.core.extensions.asUnit
import com.coinbase.wallet.core.extensions.takeSingle
import com.coinbase.wallet.core.interfaces.Destroyable
import com.coinbase.wallet.exceptions.WebSocketException
import com.coinbase.wallet.http.connectivity.Internet
import com.coinbase.wallet.http.models.WebConnectionState
import com.coinbase.wallet.http.models.WebIncomingData
import com.coinbase.wallet.http.models.WebIncomingDataType
import com.coinbase.wallet.http.models.WebIncomingText
import io.reactivex.Observable
import io.reactivex.Single
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.rxkotlin.addTo
import io.reactivex.subjects.PublishSubject
import io.reactivex.subjects.ReplaySubject
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import java.net.URL
import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

// Represents WebSocket client
class WebSocket(
    private val url: URL,
    private val connectionTimeout: Long = 15,
    private val minReconnectDelay: Long = 1,
    private val maxReconnectDelay: Long = 5
) : WebSocketListener(), Destroyable {
    private val disposeBag = CompositeDisposable()
    private val accessQueue = ReentrantLock()
    private val incomingSubject = PublishSubject.create<WebIncomingDataType>()
    private val connectionStateSubject = ReplaySubject.create<WebConnectionState>(1)
    private val client = OkHttpClient.Builder()
        .pingInterval(10, TimeUnit.SECONDS) // heartbeat
        .retryOnConnectionFailure(false)
        .build()

    private var socket: WebSocket? = null
    private var isManualClose: Boolean = false
    private var reconnectAttempts = 0
    private var isConnected: Boolean = false

    // Observable for all incoming text or data messages
    val incomingObservable: Observable<WebIncomingDataType> = incomingSubject.hide()

    // Observable for web socket connection state
    val connectionStateObservable: Observable<WebConnectionState> = connectionStateSubject.hide()

    /**
     * Connect to given web socket
     *
     * @return A single indication a successful connection. Otherwise, an error is thrown.
     */
    fun connect(): Single<Unit> {
        var isCurrentlyConnected = false

        accessQueue.withLock {
            isCurrentlyConnected = this.isConnected
            this.isManualClose = false
        }

        if (isCurrentlyConnected) {
            return Single.just(Unit)
        }

        accessQueue.withLock {
            reconnectAttempts = 0
        }

        return connectionStateObservable
            .doOnSubscribe { connectSocket() }
            .filter { it.isConnected }
            .takeSingle()
            .timeout(connectionTimeout, TimeUnit.SECONDS)
            .asUnit()
    }

    /**
    * Disconnect from websocket if connection is live
    *
    * @return A single indication connection was terminated
    */
    fun disconnect(): Single<Unit> {
        var isCurrentlyConnected = false

        accessQueue.withLock {
            isCurrentlyConnected = this.isConnected
            this.isManualClose = true
        }

        if (!isCurrentlyConnected) {
            return Single.just(Unit)
        }

        return connectionStateObservable
            .doOnSubscribe { disconnectSocket() }
            .filter { !it.isConnected }
            .takeSingle()
            .asUnit()
    }

    /**
     * Send string-based message to server
     *
     *  @param string String-based message to send
     *
     * @return A single wrapping `Void` fired when send request completes
     */
    fun sendString(string: String): Single<Unit> {
        if (socket?.send(string) == true) {
            return Single.just(Unit)
        }

        return Single.error(WebSocketException.UnableToSendData)
    }

    /**
     * Send data-based message to server
     *
     * @params string Data-based message to send
     *
     *  @returns A single wrapping `Void` fired when send request completes
     */
    fun sendData(data: ByteArray): Single<Unit> {
        val bytes = ByteString.of(data, 0, data.size)

        if (socket?.send(bytes) == true) {
            return Single.just(Unit)
        }

        return Single.error(WebSocketException.UnableToSendData)
    }

    // WebSocketListener method overrides

    override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        onDisconnect()
    }

    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        onDisconnect(t)
    }

    override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
        val data = bytes.toByteArray()
        incomingSubject.onNext(WebIncomingData(data))
    }

    override fun onMessage(webSocket: WebSocket, text: String) {
        incomingSubject.onNext(WebIncomingText(text))
    }

    override fun onOpen(webSocket: WebSocket, response: Response) {
        var isManualClose = false

        accessQueue.withLock {
            isManualClose = this.isManualClose
            isConnected = true
            reconnectAttempts = 0
        }

        connectionStateSubject.onNext(WebConnectionState.Connected())

        if (isManualClose) {
            disconnectSocket()
        }
    }

    // Destroyable

    override fun destroy(): Single<Boolean> {
        disposeBag.clear()
        return Single.just(true)
    }

    // Private

    private fun onDisconnect(t: Throwable? = null) {
        var isManualClose = false
        var delay: Long = 0

        accessQueue.withLock {
            isManualClose = this.isManualClose
            reconnectAttempts += 1

            val min = minReconnectDelay * reconnectAttempts
            delay = if (min > maxReconnectDelay) maxReconnectDelay else min
            isConnected = false
        }

        connectionStateSubject.onNext(WebConnectionState.Disconnected(t))

        // check if the connection was manually re-established. If so, make sure we reconnect.
        if (!isManualClose) {

            Internet.statusChanges
                .filter { it.isOnline }
                .take(1)
                .delay(delay, TimeUnit.SECONDS)
                .map {
                    accessQueue.withLock {
                        if (this.isManualClose) {
                            disconnectSocket()
                        } else {
                            connectSocket()
                        }
                    }
                }
                .subscribe()
                .addTo(disposeBag)
        }
    }

    // Socket helpers

    private fun connectSocket() {
        val request = Request.Builder().url(this.url).header("Origin", "").build()
        client.dispatcher().cancelAll()
        socket = client.newWebSocket(request, this)
    }

    private fun disconnectSocket() {
        client.dispatcher().cancelAll()
        socket = null
    }
}
