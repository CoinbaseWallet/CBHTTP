package com.coinbase.wallet.http.exceptions

import java.lang.Exception

sealed class HTTPException(msg: String) : Exception(msg) {
    object UnableToDeserialize : HTTPException("Unable to deserialize response")
}
