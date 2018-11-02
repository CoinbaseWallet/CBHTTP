import Foundation

/// Represents data type received via web socket
public enum HTTPWebSocketIncomingDataType {
    /// Text message received from server
    case string(String)

    /// Data message received from server
    case data(Data)
}
