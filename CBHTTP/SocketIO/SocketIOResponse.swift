// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// A Socket IO server response
public struct SocketIOResponse {
    /// Name of the event (aka channel or room)
    public let event: String

    /// Actual data received
    public let result: WebIncomingDataType
}
