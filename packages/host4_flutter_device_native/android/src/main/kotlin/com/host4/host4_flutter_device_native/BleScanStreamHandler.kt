package com.host4.host4_flutter_device_native

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import com.polidea.rxandroidble2.RxBleClient
import com.polidea.rxandroidble2.scan.ScanFilter as RxScanFilter
import com.polidea.rxandroidble2.scan.ScanSettings as RxScanSettings
import io.flutter.plugin.common.EventChannel
import io.reactivex.disposables.Disposable
import java.util.UUID

/**
 * Bridges Flutter EventChannel `host4_flutter_device_native/ble_scan` to RxAndroidBle scanning.
 */
internal class BleScanStreamHandler(
    private val applicationContext: Context,
) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var scanDisposable: Disposable? = null
    private var rxBleClient: RxBleClient? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (!BlePermissionHelper.hasAllPermissions(applicationContext)) {
            emitPermissionError()
            return
        }

        val payload = arguments as? Map<*, *>
        val serviceIds = (payload?.get("serviceIds") as? List<*>)?.mapNotNull { it as? String }
            ?: emptyList()
        startScan(serviceIds)
    }

    override fun onCancel(arguments: Any?) {
        stopScan()
        eventSink = null
    }

    fun stopScan() {
        scanDisposable?.dispose()
        scanDisposable = null
    }

    private fun emitPermissionError() {
        mainHandler.post {
            eventSink?.error(
                "ble-permission-denied",
                "BLE scan requires Bluetooth and location permissions on Android. " +
                    "Call ensureBleScanPermissions() and grant all requested permissions.",
                null,
            )
        }
    }

    private fun startScan(serviceIds: List<String>) {
        stopScan()

        val client = rxBleClient ?: RxBleClient.create(applicationContext).also { rxBleClient = it }

        val filters: List<RxScanFilter> = if (serviceIds.isEmpty()) {
            emptyList()
        } else {
            serviceIds.mapNotNull { serviceId ->
                runCatching {
                    RxScanFilter.Builder()
                        .setServiceUuid(
                            ParcelUuid(UUID.fromString(normalizeUuid(serviceId))),
                        )
                        .build()
                }.getOrNull()
            }
        }

        val scanSettings = RxScanSettings.Builder()
            .setScanMode(RxScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        val scanObservable = if (filters.isEmpty()) {
            client.scanBleDevices(scanSettings)
        } else {
            client.scanBleDevices(scanSettings, *filters.toTypedArray())
        }

        scanDisposable = scanObservable.subscribe(
            { scanResult ->
                val bleDevice = scanResult.bleDevice
                emitDevice(
                    deviceId = bleDevice.macAddress,
                    name = bleDevice.name ?: "",
                    rssi = scanResult.rssi,
                )
            },
            { error ->
                mainHandler.post {
                    eventSink?.error(
                        "ble-scan-error",
                        error.message,
                        null,
                    )
                }
            },
        )
    }

    private fun emitDevice(deviceId: String, name: String, rssi: Int) {
        val event = mapOf(
            "deviceId" to deviceId,
            "name" to name,
            "kind" to "ble",
            "metadata" to mapOf("rssi" to rssi),
        )
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    private fun normalizeUuid(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.contains("-")) {
            return trimmed
        }
        if (trimmed.length != 4 && trimmed.length != 8 && trimmed.length != 32) {
            return trimmed
        }
        val padded = trimmed.padStart(32, '0')
        return buildString {
            append(padded.substring(0, 8))
            append('-')
            append(padded.substring(8, 12))
            append('-')
            append(padded.substring(12, 16))
            append('-')
            append(padded.substring(16, 20))
            append('-')
            append(padded.substring(20, 32))
        }
    }
}
