// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import RxSwift
import Starscream

/// Represents an HTTP web socket
public final class WebSocket: WebSocketDelegate {
    private let accessQueue = DispatchQueue(label: "CBHTTP.WebSocket.accessQueue")
    private let socket: Starscream.WebSocket
    private let incomingSubject = PublishSubject<WebIncomingDataType>()
    private let connectionStateSubject = BehaviorSubject<WebConnectionState>(value: .disconnected(nil))
    private let minReconnectDelay: TimeInterval
    private let maxReconnectDelay: TimeInterval
    private let connectionTimeout: TimeInterval
    private var isManualClose = false
    private var reconnectAttempts: UInt64 = 0
    private var heartbeatDisposeBag = DisposeBag()
    private var isConnected: Bool = false
    private lazy var serialScheduler = SerialDispatchQueueScheduler(
        queue: self.accessQueue,
        internalSerialQueueName: "CBHTTP.WebSocket.serialScheduler"
    )

    /// Observable for all incoming text or data messages
    public let incomingObservable: Observable<WebIncomingDataType>

    /// Observable for web socket connection state
    public let connectionStateObservable: Observable<WebConnectionState>

    /// Default constructor for given URL
    ///
    /// - Parameters:
    ///     - url: Websocket URL
    ///     - connectionTimeout: number of seconds before connection attempts timeout.
    ///     - minReconnectDelay: Min number of seconds to wait before reconnecting.
    ///     - maxReconnectDelay: Max number of seconds to wait before reconnecting.
    public init(
        url: URL,
        connectionTimeout: TimeInterval = 15,
        minReconnectDelay: TimeInterval = 1,
        maxReconnectDelay: TimeInterval = 5
    ) {
        self.connectionTimeout = connectionTimeout
        self.minReconnectDelay = minReconnectDelay
        self.maxReconnectDelay = maxReconnectDelay

        incomingObservable = incomingSubject.asObservable()
        connectionStateObservable = connectionStateSubject.asObservable()

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = ["Origin": ""]

        socket = Starscream.WebSocket(request: request)
        socket.delegate = self
        socket.callbackQueue = DispatchQueue(label: "WebSocket.socket.callbackQueue")
    }

    /// Connect to given web socket
    ///
    /// - Returns: A single indication a successful connection. Otherwise, an error is thrown.
    public func connect() -> Single<Void> {
        var isCurrentlyConnected = false

        accessQueue.sync {
            isCurrentlyConnected = self.isConnected
            self.isManualClose = false
        }

        if isCurrentlyConnected {
            return .just(())
        }

        accessQueue.sync {
            self.reconnectAttempts = 0
        }

        return connectionStateObservable
            .do(onSubscribed: {
                DispatchQueue.global(qos: .userInitiated).async { self.socket.connect() }
            })
            .filter { $0.isConnected }
            .take(1)
            .asSingle()
            .timeout(connectionTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .flatMap { _ in .just(()) }
    }

    /// Disconnect from websocket if connection is live
    ///
    /// - Returns: A single indication connection was terminated
    public func disconnect() -> Single<Void> {
        var isCurrentlyConnected = false

        accessQueue.sync {
            isCurrentlyConnected = self.isConnected
            self.isManualClose = true
        }

        guard isCurrentlyConnected else { return .just(()) }

        return connectionStateObservable
            .do(onSubscribed: {
                DispatchQueue.global(qos: .userInitiated).async { self.socket.disconnect() }
            })
            .filter { !$0.isConnected }
            .take(1)
            .asSingle()
            .flatMap { _ in .just(()) }
    }

    /// Send string-based message to server
    ///
    /// - Parameters:
    ///     - string: String-based message to send
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func sendString(_ string: String) -> Single<Void> {
        return Single.create { observer -> Disposable in
            self.socket.write(string: string) { observer(.success(())) }
            return Disposables.create()
        }
    }

    /// Send data-based message to server
    ///
    /// - Parameters:
    ///     - string: Data-based message to send
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func sendData(_ data: Data) -> Single<Void> {
        return Single.create { observer -> Disposable in
            self.socket.write(data: data) { observer(.success(())) }
            return Disposables.create()
        }
    }

    deinit {
        _ = disconnect().subscribe()
    }

    // MARK: - WebSocketDelegate

    public func websocketDidConnect(socket _: WebSocketClient) {
        var isManualClose = false

        accessQueue.sync {
            isManualClose = self.isManualClose

            self.isConnected = true
            self.reconnectAttempts = 0
            self.startHeartbeat()
        }

        connectionStateSubject.onNext(.connected)

        // check if the connection was manually closed. If so, force a disconnect
        if isManualClose {
            socket.disconnect()
        }
    }

    public func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        var isManualClose = false
        var delay: TimeInterval = 0

        accessQueue.sync {
            isManualClose = self.isManualClose

            self.reconnectAttempts += 1

            delay = min(self.minReconnectDelay * TimeInterval(self.reconnectAttempts), self.maxReconnectDelay)

            self.isConnected = false
            self.stopHeartbeat()
        }

        connectionStateSubject.onNext(.disconnected(error))

        // check if the connection was manually re-established. If so, make sure we reconnect.
        if !isManualClose {
            _ = Internet.statusChanges
                .filter { $0.isOnline }
                .take(1)
                .delay(RxTimeInterval(delay), scheduler: serialScheduler)
                .map { [weak self] _ in
                    if self?.isManualClose == true {
                        self?.socket.disconnect()
                    } else {
                        self?.socket.connect()
                    }
                }
                .asSingle()
                .subscribe()
        }
    }

    public func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
        incomingSubject.onNext(.text(text))
    }

    public func websocketDidReceiveData(socket _: WebSocketClient, data: Data) {
        incomingSubject.onNext(.data(data))
    }

    // MARK: - Heartbeats

    private func startHeartbeat() {
        Observable<Int>.interval(10, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] _ in self?.socket.write(ping: Data()) })
            .disposed(by: heartbeatDisposeBag)
    }

    private func stopHeartbeat() {
        heartbeatDisposeBag = DisposeBag()
    }
}
