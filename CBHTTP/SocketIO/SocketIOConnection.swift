// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import os.log
import RxSwift
import SocketIO

/// Represents an HTTP socket io connection
public final class SocketIOConnection {
    private let url: URL
    private let connectionStateSubject = BehaviorSubject<WebConnectionState>(value: .disconnected(nil))
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var didDisconnectObserverUuid: UUID?
    private var didConnectObserverUuid: UUID?

    /// Observable for socket io connection state
    public let connectionStateObservable: Observable<WebConnectionState>

    public init(url: URL) {
        self.url = url
        connectionStateObservable = connectionStateSubject.asObservable()
    }

    /// Connect to given socket io server
    ///
    /// - Parameters:
    ///     - headers: Optional extra headers to include
    ///
    /// - Returns: A single indication a successful connection. Otherwise, an error is thrown.
    public func connect(headers: [String: String] = [:]) -> Single<Void> {
        if socket?.status == .connected || socket?.status == .connecting {
            return .just(())
        }

        manager = SocketManager(socketURL: url, config: [.extraHeaders(headers)])
        socket = manager?.defaultSocket
        observeDidConnect()
        observerDidDisconnect()

        return connectionStateObservable
            .do(onSubscribed: { [weak self] in self?.socket?.connect() })
            .filter { $0.isConnected }
            .take(1)
            .asSingle()
            .flatMap { _ in .just(()) }
    }

    /// Disconnect from socket io if connection is live
    ///
    /// - Returns: A single indication connection was terminated
    public func disconnect() -> Single<Void> {
        guard socket?.status == .connected || socket?.status == .connecting else { return .just(()) }

        return connectionStateObservable
            .do(onSubscribed: { [weak self] in self?.socket?.disconnect() })
            .do(onCompleted: { [weak self] in
                self?.disregardDidDisconnect()
                self?.disregardDidConnect()
                self?.socket = nil
                self?.manager = nil
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
    ///     - event: This is synonymous with room or channel
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func sendString(_ string: String, event: String) -> Single<Void> {
        return Single.create { observer -> Disposable in
            guard let socket = self.socket else {
                observer(.success(()))
                return Disposables.create()
            }

            socket.emit(event, string) { observer(.success(())) }

            return Disposables.create()
        }
    }

    /// Send string-based message to server
    ///
    /// - Parameters:
    ///     - data: Data-based message to send
    ///     - event: This is synonymous with room or channel
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func sendData(_ data: Data, event: String) -> Single<Void> {
        return Single.create { observer -> Disposable in
            guard let socket = self.socket else {
                observer(.success(()))
                return Disposables.create()
            }

            socket.emit(event, data) { observer(.success(())) }

            return Disposables.create()
        }
    }

    /// Observe event for incoming data
    ///
    /// - Parameters:
    ///     - event: This is synonymous with room or channel
    ///
    /// - Returns: An observable for incoming text or data messages for given event
    public func observe(event: String) -> Observable<SocketIOResponse> {
        return Observable<SocketIOResponse>.create { [weak self] observer -> Disposable in
            let uuid = self?.socket?.on(event) { data, _ in
                let result: WebIncomingDataType

                if let string = data.first as? String {
                    result = .text(string)
                } else if let bytes = data.first as? Data {
                    result = .data(bytes)
                } else {
                    return os_log("[http] SocketIO unsupported data type %@", type: .debug, data)
                }

                let response = SocketIOResponse(event: event, result: result)

                observer.onNext(response)
            }

            return Disposables.create {
                guard let uuid = uuid else { return }
                self?.socket?.off(id: uuid)
            }
        }
    }

    deinit {
        _ = disconnect().subscribe()
    }

    // MARK: - Observers

    private func observeDidConnect() {
        disregardDidConnect()
        didConnectObserverUuid = socket?.on(clientEvent: .connect) { [weak self] _, _ in
            os_log("[http] socket connected", type: .debug)
            self?.connectionStateSubject.onNext(.connected)
        }
    }

    private func observerDidDisconnect() {
        disregardDidDisconnect()
        didDisconnectObserverUuid = socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            os_log("[http] socket disconnected", type: .debug)
            self?.connectionStateSubject.onNext(.disconnected(nil))
        }
    }

    private func disregardDidConnect() {
        didConnectObserverUuid.map { socket?.off(id: $0) }
    }

    private func disregardDidDisconnect() {
        didDisconnectObserverUuid.map { socket?.off(id: $0) }
    }
}
