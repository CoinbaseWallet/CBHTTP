// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represent a network connection type
public enum ConnectionKind: Equatable {
    /// Connected over wifi
    case wifi

    /// Connected over wwan
    case wwan
}
