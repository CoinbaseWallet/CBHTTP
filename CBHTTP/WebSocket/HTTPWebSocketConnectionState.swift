import Foundation

/// Represents connection state of the web socket
public enum HTTPWebSocketConnectionState {
    /// The websocket is not currently connected
    case disconnected(Error?)

    /// A websocket connection is currently live
    case connected
}
