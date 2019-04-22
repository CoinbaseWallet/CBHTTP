// Copyright (c) 2017-2019 Coinbase Inc. See LICENSE

import Foundation

/// Represents data type received via web live connection
public enum WebIncomingDataType {
    /// Text message received from server
    case string(String)

    /// Data message received from server
    case data(Data)
}
