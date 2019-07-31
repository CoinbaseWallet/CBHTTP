package com.coinbase.wallet.http.models

// Represents connection state of any web connection
sealed class WebConnectionState {
    // The connection is currently live
    class Connected : WebConnectionState()

    // The connection is not currently live
    data class Disconnected(val t: Throwable?) : WebConnectionState()

    // Determine whether web connection is established
    val isConnected: Boolean
    get() = when (this) {
        is Connected -> true
        is Disconnected -> false
    }
}
