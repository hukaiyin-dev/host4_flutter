package com.host4.host4_flutter_device_native

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

internal class GmacroTurbo16BatchTest {
    @Test
    fun timingFormKeepsEachDurationAndInterval() {
        val sent = mutableListOf<List<Int>>()
        GmacroTurbo16Batch.send(
            listOf(
                mapOf("key" to 0xA0, "turbo" to 1, "pressDuration" to 300, "interval" to 600),
                mapOf("key" to 0xA1, "turbo" to 2, "pressDuration" to 0, "interval" to 12000),
            ),
            pressDuration = null,
            device = 2,
            sendOne = { key, turbo, duration, interval, device, callback ->
                sent += listOf(key, turbo, duration, interval, device)
                callback(GmacroResult.Success(emptyMap<String, Any>()))
            },
            onResult = {},
        )
        assertEquals(listOf(listOf(0xA0, 1, 300, 600, 2), listOf(0xA1, 2, 0, 12000, 2)), sent)
    }

    @Test
    fun sendsEveryKeyInOrderAndCompletesOnce() {
        val sent = mutableListOf<List<Int>>()
        val results = mutableListOf<GmacroResult>()
        GmacroTurbo16Batch.send(
            listOf(
                mapOf("key" to 0xA0, "turbo" to 1, "speed" to 300),
                mapOf("key" to 0xA1, "turbo" to 2, "speed" to 400),
            ),
            pressDuration = 5,
            device = 3,
            sendOne = { key, turbo, duration, speed, device, callback ->
                sent += listOf(key, turbo, duration, speed, device)
                callback(GmacroResult.Success(emptyMap<String, Any>()))
            },
            onResult = results::add,
        )
        assertEquals(listOf(listOf(0xA0, 1, 5, 300, 3), listOf(0xA1, 2, 5, 400, 3)), sent)
        assertEquals(1, results.size)
        assertIs<GmacroResult.Success>(results.single())
    }

    @Test
    fun stopsAfterFirstFailure() {
        val sent = mutableListOf<Int>()
        val results = mutableListOf<GmacroResult>()
        GmacroTurbo16Batch.send(
            listOf(mapOf("key" to 0xA0, "turbo" to 1, "speed" to 300),
                mapOf("key" to 0xA1, "turbo" to 1, "speed" to 400)),
            pressDuration = 1,
            device = 0,
            sendOne = { key, _, _, _, _, callback ->
                sent += key
                callback(GmacroResult.Error("failed", "device rejected"))
            },
            onResult = results::add,
        )
        assertEquals(listOf(0xA0), sent)
        assertEquals(1, results.size)
        assertIs<GmacroResult.Error>(results.single())
    }
}
