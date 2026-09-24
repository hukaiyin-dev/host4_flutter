package com.host4.host4_flutter_device_native

import com.host4.platform.util.Constants
import io.flutter.plugin.common.MethodChannel

/**
 * Transport-neutral GMacro method result. USB direct and AIDL backends share this shape;
 * MethodChannel only converts it to [MethodChannel.Result].
 */
sealed class GmacroResult {
    data class Success(val payload: Any?) : GmacroResult()

    data class Error(
        val code: String,
        val message: String?,
        val details: Any? = null,
    ) : GmacroResult()

    fun deliverTo(result: MethodChannel.Result) {
        when (this) {
            is Success -> result.success(payload)
            is Error -> result.error(code, message, details)
        }
    }

    companion object {
        const val FAILED_CODE = "gmacro-method-failed"
        const val INVALID_ARGUMENTS = "invalid-arguments"
        const val INVOCATION_ERROR = "gmacro-invocation-error"
        const val UNSUPPORTED_METHOD = "unsupported-gmacro-method"

        fun fromProtocol(code: Int, successPayload: Any?, errorDetails: Any? = successPayload): GmacroResult {
            return if (isProtocolSuccess(code)) {
                Success(successPayload)
            } else {
                Error(
                    FAILED_CODE,
                    "GMacro method failed with code=$code",
                    errorDetails,
                )
            }
        }

        fun isProtocolSuccess(code: Int): Boolean {
            return code == Constants.SUCCESS || code == 80
        }

        fun unsupported(method: String): Error {
            return Error(
                UNSUPPORTED_METHOD,
                "Unsupported GMacro method on Android: $method",
            )
        }

        fun invalidArguments(message: String?): Error {
            return Error(INVALID_ARGUMENTS, message)
        }

        fun invocationError(method: String, error: Throwable): Error {
            return Error(
                INVOCATION_ERROR,
                error.message ?: "Failed to invoke GMacro method '$method'.",
            )
        }
    }
}
