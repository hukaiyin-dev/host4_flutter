package com.host4.host4_flutter_device_native

import android.content.Context
import android.hardware.usb.UsbManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Lists attached USB devices for Flutter EventChannel `host4_flutter_device_native/usb_scan`.
 */
internal class UsbScanStreamHandler(
    private val applicationContext: Context,
) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var refreshRunnable: Runnable? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        publishAttachedDevices()
        scheduleRefresh()
    }

    override fun onCancel(arguments: Any?) {
        cancelRefresh()
        eventSink = null
    }

    fun stopScan() {
        cancelRefresh()
    }

    private fun scheduleRefresh() {
        cancelRefresh()
        val runnable = object : Runnable {
            override fun run() {
                publishAttachedDevices()
                mainHandler.postDelayed(this, REFRESH_INTERVAL_MS)
            }
        }
        refreshRunnable = runnable
        mainHandler.postDelayed(runnable, REFRESH_INTERVAL_MS)
    }

    private fun cancelRefresh() {
        refreshRunnable?.let { mainHandler.removeCallbacks(it) }
        refreshRunnable = null
    }

    private fun publishAttachedDevices() {
        val sink = eventSink ?: return
        val usbManager =
            applicationContext.getSystemService(Context.USB_SERVICE) as? UsbManager
        if (usbManager == null) {
            mainHandler.post {
                sink.error(
                    "usb-manager-unavailable",
                    "UsbManager is not available on this device.",
                    null,
                )
            }
            return
        }

        val devices = usbManager.deviceList.values
        if (devices.isEmpty()) {
            return
        }

        mainHandler.post {
            for (device in devices) {
                val deviceId = UsbDeviceIds.format(device.vendorId, device.productId)
                val name = device.productName?.takeIf { it.isNotBlank() }
                    ?: device.deviceName
                    ?: "USB Device"
                sink.success(
                    mapOf(
                        "deviceId" to deviceId,
                        "name" to name,
                        "kind" to "usb",
                        "metadata" to mapOf(
                            "vendorId" to device.vendorId,
                            "productId" to device.productId,
                            "deviceName" to device.deviceName,
                            "hasPermission" to usbManager.hasPermission(device),
                        ),
                    ),
                )
            }
        }
    }

    companion object {
        private const val REFRESH_INTERVAL_MS = 1500L
    }
}
