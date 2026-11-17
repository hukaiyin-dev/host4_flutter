package com.host4.host4_flutter_device_native

import kotlin.test.Test
import kotlin.test.assertEquals

internal class UsbDeviceIdsTest {
    @Test
    fun scannedHexIdFiltersTheSelectedXboxController() {
        val id = UsbDeviceIds.format(1118, 654)

        assertEquals("45e:28e", id)
        val filter = UsbDeviceIds.parseFilter(id, null)
        assertEquals(listOf(1118), filter.vids?.toList())
        assertEquals(listOf(654), filter.pids?.toList())
    }
}
