package com.host4.host4_flutter_device_native.broker

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class BrokerServiceLaunchPolicyTest {
    @Test
    fun startThenBind_startsServiceBeforeBinding() {
        val calls = mutableListOf<String>()

        val bound = BrokerServiceLaunchPolicy.startThenBind(
            startService = { calls.add("start") },
            bindService = {
                calls.add("bind")
                true
            },
        )

        assertTrue(bound)
        assertEquals(listOf("start", "bind"), calls)
    }

    @Test
    fun startThenBind_stillBindsWhenForegroundStartIsRejected() {
        val calls = mutableListOf<String>()

        val bound = BrokerServiceLaunchPolicy.startThenBind(
            startService = {
                calls.add("start")
                error("background start rejected")
            },
            bindService = {
                calls.add("bind")
                true
            },
        )

        assertTrue(bound)
        assertEquals(listOf("start", "bind"), calls)
    }

    @Test
    fun startThenBind_returnsFalseWhenBindingThrows() {
        val bound = BrokerServiceLaunchPolicy.startThenBind(
            startService = {},
            bindService = { error("service process is not ready") },
        )

        assertEquals(false, bound)
    }
}
