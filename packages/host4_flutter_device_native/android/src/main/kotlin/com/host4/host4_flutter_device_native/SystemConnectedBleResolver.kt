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
    fun listDevices(context: Context, platformSdk: FullPlatformSdk): List<BluetoothDevice> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        val devices = linkedMapOf<String, BluetoothDevice>()
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothManager?.getConnectedDevices(BluetoothProfile.GATT)?.forEach { device ->
            devices[BleMacUtils.normalizeMac(device.address)] = device
        }
        platformSdk.getConnectedBleDevices().forEach { mac ->
            runCatching { adapter.getRemoteDevice(mac) }.getOrNull()?.let { device ->
                devices[BleMacUtils.normalizeMac(device.address)] = device
            }
        }
        adapter.bondedDevices?.forEach { device ->
            devices.putIfAbsent(BleMacUtils.normalizeMac(device.address), device)
        }
        return devices.values.toList()
    }

    fun resolveMac(
        context: Context,
        platformSdk: FullPlatformSdk,
        deviceNames: List<String>,
    ): String? {
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

        listDevices(context, platformSdk)
            .firstOrNull { it.matchesName() }
            ?.address
            ?.let { return BleMacUtils.normalizeMac(it) }

        return null
    }
}
