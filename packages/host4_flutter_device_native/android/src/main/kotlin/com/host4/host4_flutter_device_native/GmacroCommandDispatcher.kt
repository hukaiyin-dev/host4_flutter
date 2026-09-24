package com.host4.host4_flutter_device_native

import com.host4.host4_flutter_device_native.broker.DeviceBrokerContract

/**
 * Shared GMacro command entry used by USB/BLE ([DirectPlatformBackend]) and later AIDL.
 */
internal fun interface GmacroCommandBackend {
    fun invoke(method: String, arguments: Map<String, Any?>, callback: (GmacroResult) -> Unit)
}

internal class DirectPlatformBackend(
    private val deviceKey: String,
    private val transportKind: String,
) : GmacroCommandBackend {
    override fun invoke(
        method: String,
        arguments: Map<String, Any?>,
        callback: (GmacroResult) -> Unit,
    ) {
        GmacroMethodInvoker.invoke(
            deviceKey = deviceKey,
            transportKind = transportKind,
            method = method,
            arguments = arguments,
            onResult = callback,
        )
    }
}

internal class GmacroCommandDispatcher(
    private val backend: GmacroCommandBackend,
) {
    fun invoke(
        method: String,
        arguments: Map<String, Any?>,
        callback: (GmacroResult) -> Unit,
    ) {
        try {
            backend.invoke(method, arguments, callback)
        } catch (error: IllegalArgumentException) {
            callback(GmacroResult.invalidArguments(error.message))
        } catch (error: Exception) {
            callback(GmacroResult.invocationError(method, error))
        }
    }
}

/**
 * Public service-side entry point used by Pantas' isolated DeviceBroker process.
 *
 * Keeping this facade in Host4 guarantees that direct USB calls and brokered UART
 * calls share the exact same argument parsing, protocol callbacks and result maps.
 */
class GmacroBrokerCommandDispatcher {
    private val delegate = GmacroCommandDispatcher(
        DirectPlatformBackend(
            deviceKey = DeviceBrokerContract.UART_DEVICE_ID,
            transportKind = Host4FlutterTransportKinds.UART,
        ),
    )

    fun invoke(
        method: String,
        arguments: Map<String, Any?>,
        callback: (GmacroResult) -> Unit,
    ) {
        delegate.invoke(method, arguments, callback)
    }
}
