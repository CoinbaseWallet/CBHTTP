// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represents data type received via web socket
public enum HTTPWebSocketIncomingDataType {
    /// Text message received from server
    case string(String)

    /// Data message received from server
    case data(Data)
}
