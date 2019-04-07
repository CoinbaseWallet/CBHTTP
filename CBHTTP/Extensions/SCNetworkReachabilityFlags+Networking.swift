// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import SystemConfiguration

extension SCNetworkReachabilityFlags {
    /// Determine whether network is available and reachable
    var isNetworkReachable: Bool {
        let flags = self
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)

        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
