package com.host4.host4_flutter_device_native

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import com.host4.platform.v2.api.FullPlatformSdk
import com.host4.platform.v2.ble.BleMacUtils

/**
 * Resolves a BLE MAC for "system connected" connect, mirroring iOS
 * `retrieveSystemConnectedPeripheral` + bonded-device fallback.
 */
internal object SystemConnectedBleResolver {
    fun resolveMac(
        context: Context,
        platformSdk: FullPlatformSdk,
        deviceNames: List<String>,
    ): String? {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return null
        val normalizedNames = deviceNames.map { it.trim() }.filter { it.isNotEmpty() }

        fun BluetoothDevice.matchesName(): Boolean {
            if (normalizedNames.isEmpty()) {
                return true
            }
            val deviceName = name ?: return false
            return normalizedNames.any { candidate ->
                deviceName.equals(candidate, ignoreCase = true) ||
                    deviceName.contains(candidate, ignoreCase = true)
            }
        }

        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothManager
            ?.getConnectedDevices(BluetoothProfile.GATT)
            ?.firstOrNull { it.matchesName() }
            ?.address
            ?.let { return BleMacUtils.normalizeMac(it) }

        @Suppress("UNCHECKED_CAST")
        val sdkConnectedMacs =
            platformSdk.getConnectedBleDevices() as? List<String> ?: emptyList()
        for (mac in sdkConnectedMacs) {
            val device = runCatching { adapter.getRemoteDevice(mac) }.getOrNull() ?: continue
            if (device.matchesName()) {
                return BleMacUtils.normalizeMac(mac)
            }
        }

        adapter.bondedDevices
            ?.firstOrNull { it.matchesName() }
            ?.address
            ?.let { return BleMacUtils.normalizeMac(it) }

        return null
    }
}
