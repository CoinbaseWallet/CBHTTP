package com.coinbase.wallet.http.connectivity

/**
 * Represents data type received via web live connection
 */
sealed class ConnectionStatus {
    /**
     * Network is online using the given network kind i.e. wifi, wwan, etc
     */
    data class Connected(val kind: ConnectionKind) : ConnectionStatus()

    /**
     * Network is offline
     */
    object Offline : ConnectionStatus()

    /**
     * Network status is unknown
     */
    object Unknown : ConnectionStatus()

    /**
     * Network is online
     */
    val isOnline: Boolean get() = this is Connected
}
