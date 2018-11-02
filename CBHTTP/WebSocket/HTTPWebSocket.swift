import RxSwift
import Starscream

/// Represents an HTTP web socket
public final class HTTPWebSocket {
    private let handler: HTTPWebSocketHandler

    /// Observable for all incoming text or data messages
    public let incomingObservable: Observable<HTTPWebSocketIncomingDataType>

    /// Observable for web socket connection state
    public let connectionStateObservable: Observable<HTTPWebSocketConnectionState>

    /// Default constructor for given URL
    public init(url: URL) {
        let socket = WebSocket(url: url)
        let handler = HTTPWebSocketHandler(socket: socket)

        self.handler = handler
        incomingObservable = handler.incomingSubject.asObservable()
        connectionStateObservable = handler.connectionStateSubject.asObservable()
    }

    /// Connect to given web socket
    public func connect() {
        handler.socket.connect()
    }

    /// Disconnect from websocket if connection is live
    public func disconnect() {
        guard handler.socket.isConnected else { return }
        handler.socket.disconnect()
    }

    /// Send string-based message to server
    ///
    /// - Parameters:
    ///     - string: String-based message to send
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func send(string: String) -> Single<Void> {
        return Single.create { observer -> Disposable in
            self.handler.socket.write(string: string) { observer(.success(())) }
            return Disposables.create()
        }
    }

    /// Send string-based message to server
    ///
    /// - Parameters:
    ///     - string: Data-based message to send
    ///
    /// - Returns: A single wrapping `Void` fired when send request completes
    public func send(data: Data) -> Single<Void> {
        return Single.create { observer -> Disposable in
            self.handler.socket.write(data: data) { observer(.success(())) }
            return Disposables.create()
        }
    }

    deinit {
        disconnect()
    }
}


/// This is fileprivate to abstract away StarStream
final fileprivate class HTTPWebSocketHandler: WebSocketDelegate {
    fileprivate let socket: WebSocket
    fileprivate let incomingSubject = PublishSubject<HTTPWebSocketIncomingDataType>()
    fileprivate let connectionStateSubject = PublishSubject<HTTPWebSocketConnectionState>()

    init(socket: WebSocket) {
        self.socket = socket
    }

    func websocketDidConnect(socket: WebSocketClient) {
        connectionStateSubject.onNext(.connected)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        connectionStateSubject.onNext(.disconnected(error))
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        incomingSubject.onNext(.string(text))
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        incomingSubject.onNext(.data(data))
    }
}
