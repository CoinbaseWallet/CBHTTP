// Copyright (c) 2017-2018 Coinbase Inc. See LICENSE

import SystemConfiguration

/// Represents network status
public enum ConnectionStatus: Equatable {
    /// Network is online using the given network kind i.e. wifi, wwan, etc
    case connected(ConnectionKind)

    /// Network is offline
    case offline

    /// Network status is unknown
    case unknown

    /// Network is online
    public var isOnline: Bool {
        guard case .connected = self else { return false }
        return true
    }

    init(flags: SCNetworkReachabilityFlags) {
        if flags.isNetworkReachable {
            // Currently online
            self = flags.contains(.isWWAN) ? .connected(.wwan) : .connected(.wifi)
        } else {
            // Currently offline
            self = .offline
        }
    }
}
