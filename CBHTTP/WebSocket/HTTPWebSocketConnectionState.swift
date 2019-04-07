// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represents connection state of the web socket
public enum HTTPWebSocketConnectionState {
    /// The websocket is not currently connected
    case disconnected(Error?)

    /// A websocket connection is currently live
    case connected

    /// Determine whether socket is connected
    var isConnected: Bool {
        guard case .connected = self else { return false }

        return true
    }
}
