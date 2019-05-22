// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represents connection state of any web connection
public enum WebConnectionState {
    /// The connection is not currently live
    case disconnected(Error?)

    /// The connection is currently live
    case connected

    /// Determine whether connection is live
    public var isConnected: Bool {
        guard case .connected = self else { return false }

        return true
    }
}
