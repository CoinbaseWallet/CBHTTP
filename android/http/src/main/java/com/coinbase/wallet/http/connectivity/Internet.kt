package com.coinbase.wallet.http.connectivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import android.provider.Settings
import com.coinbase.wallet.http.connectivity.ConnectionKind.CELL
import com.coinbase.wallet.http.connectivity.ConnectionKind.UNKNOWN
import com.coinbase.wallet.http.connectivity.ConnectionKind.WIFI
import com.coinbase.wallet.http.connectivity.ConnectionStatus.Connected
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.rxkotlin.addTo
import io.reactivex.schedulers.Schedulers
import io.reactivex.subjects.BehaviorSubject
import io.reactivex.subjects.ReplaySubject
import timber.log.Timber
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

object Internet : BroadcastReceiver() {
    private val disposeBag = CompositeDisposable()
    private val serialScheduler = Schedulers.single()
    private val networkUpdatesSubject = ReplaySubject.createWithSize<Context>(1)
    private val changes = BehaviorSubject.createDefault<ConnectionStatus>(ConnectionStatus.Unknown)

    /**
     * Get the current network status
     */
    var status: ConnectionStatus = ConnectionStatus.Unknown
        private set

    /**
     * Observer for new network status changes
     */
    val statusChanges = changes.hide()

    /**
     * Determine whether network is online or not
     */
    val isOnline: Boolean get() = status.isOnline

    /**
     * Start monitoring network changes
     */
    fun startMonitoring() {
        networkUpdatesSubject
            .observeOn(serialScheduler)
            .map { context ->
                val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val activeNetwork = cm.activeNetwork
                val activeNetworkInfo = cm.activeNetworkInfo

                if (activeNetwork == null) {
                    if (Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) != 0) {
                        ConnectionStatus.Offline
                    } else {
                        ConnectionStatus.Unknown
                    }
                    .let {
                        status = it
                        changes.onNext(it)
                    }

                    return@map
                }

                status = if (activeNetworkInfo?.isConnected == true && isServerReachable()) {
                    getStatus(cm.getNetworkCapabilities(activeNetwork))
                } else {
                    ConnectionStatus.Offline
                }

                changes.onNext(status)
            }
            .onErrorReturn { Timber.e(it, "Unable to determine internet status") }
            .subscribe()
            .addTo(disposeBag)
    }

    /**
     * Stop monitoring network changes
     */
    fun stopMonitoring() {
        disposeBag.clear()
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ConnectivityManager.CONNECTIVITY_ACTION) {
            networkUpdatesSubject.onNext(context)
        }
    }

    // Helpers

    private fun getStatus(capabilities: NetworkCapabilities?): ConnectionStatus {
        if (capabilities == null) {
            return Connected(UNKNOWN)
        }

        val hasCell = capabilities.hasTransport(TRANSPORT_CELLULAR)
        val hasWifi = capabilities.hasTransport(TRANSPORT_WIFI)

        return when {
            hasCell && !hasWifi -> Connected(CELL)
            hasWifi -> Connected(WIFI)
            else -> Connected(UNKNOWN)
        }
    }

    private fun isServerReachable(): Boolean = try {
        URL("https://www.google.com")
            .openConnection()
            .let { it as HttpURLConnection }
            .apply {
                instanceFollowRedirects = false
                setRequestProperty("Connection", "close")
                connectTimeout = 1500
                connect()
            }
            .responseCode == 200
    } catch (e: IOException) {
        false
    }
}
