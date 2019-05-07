// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import RxSwift
import Starscream

/// Represents an HTTP web socket
public final class WebSocket: WebSocketDelegate {
    private let socket: Starscream.WebSocket
    private let incomingSubject = PublishSubject<WebIncomingDataType>()
    private let connectionStateSubject = BehaviorSubject<WebConnectionState>(value: .disconnected(nil))
    private let minReconnectDelay: TimeInterval
    private let maxReconnectDelay: TimeInterval
    private let connectionTimeout: TimeInterval
    private var isAutoReconnectEnabled = false
    private var reconnectAttempts: UInt64 = 0
    private var heartbeatDisposeBag = DisposeBag()

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

        socket = Starscream.WebSocket(url: url)
        socket.delegate = self
        socket.callbackQueue = DispatchQueue(label: "WebSocket.socket.callbackQueue")
    }

    /// Connect to given web socket
    ///
    /// - Returns: A single indication a successful connection. Otherwise, an error is thrown.
    public func connect() -> Single<Void> {
        isAutoReconnectEnabled = true
        if socket.isConnected {
            return .just(())
        }

        return connectionStateObservable
            .do(onSubscribed: { [weak self] in self?.socket.connect() })
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
        isAutoReconnectEnabled = false

        guard socket.isConnected else { return .just(()) }

        return connectionStateObservable
            .do(onSubscribed: { [weak self] in self?.socket.disconnect() })
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
        reconnectAttempts = 0
        connectionStateSubject.onNext(.connected)
        startHeartbeat()
    }

    public func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        stopHeartbeat()
        connectionStateSubject.onNext(.disconnected(error))

        if isAutoReconnectEnabled {
            reconnectAttempts += 1

            let delay = min(minReconnectDelay * TimeInterval(reconnectAttempts), maxReconnectDelay)

            _ = Internet.statusChanges
                .filter { $0.isOnline }
                .take(1)
                .delay(RxTimeInterval(delay), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .map { [weak self] _ in self?.socket.connect() }
                .asSingle()
                .subscribe()
        }
    }

    public func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
        incomingSubject.onNext(.string(text))
    }

    public func websocketDidReceiveData(socket _: WebSocketClient, data: Data) {
        incomingSubject.onNext(.data(data))
    }

    // MARK: - Heartbeats

    private func startHeartbeat() {
        Observable<Int>.interval(10, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .startWith(0)
            .subscribe(onNext: { [weak self] _ in self?.socket.write(ping: Data()) })
            .disposed(by: heartbeatDisposeBag)
    }

    private func stopHeartbeat() {
        heartbeatDisposeBag = DisposeBag()
    }
}
