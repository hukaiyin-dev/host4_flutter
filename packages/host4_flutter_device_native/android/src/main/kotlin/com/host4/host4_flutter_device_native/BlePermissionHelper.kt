package com.host4.host4_flutter_device_native

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

internal object BlePermissionHelper {
    const val REQUEST_BLE_PERMISSIONS = 9101

    fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                // RxAndroidBle 1.x still checks location even on Android 12+.
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
            )
        }
    }

    fun missingPermissions(context: Context): List<String> {
        return requiredPermissions().filter { permission ->
            ContextCompat.checkSelfPermission(context, permission) !=
                PackageManager.PERMISSION_GRANTED
        }
    }

    fun hasAllPermissions(context: Context): Boolean {
        return missingPermissions(context).isEmpty()
    }

    fun requestMissingPermissions(activity: Activity): Boolean {
        val missing = missingPermissions(activity)
        if (missing.isEmpty()) {
            return true
        }
        ActivityCompat.requestPermissions(
            activity,
            missing.toTypedArray(),
            REQUEST_BLE_PERMISSIONS,
        )
        return false
    }
}
