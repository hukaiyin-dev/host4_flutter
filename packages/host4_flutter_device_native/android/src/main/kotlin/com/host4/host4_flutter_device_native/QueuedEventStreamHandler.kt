package com.host4.host4_flutter_device_native

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

internal class QueuedEventStreamHandler : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private val bufferedEvents = mutableListOf<Map<String, Any?>>()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sink = events ?: return
        bufferedEvents.forEach { sink.success(it) }
        bufferedEvents.clear()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            val sink = eventSink
            if (sink != null) {
                sink.success(event)
            } else {
                bufferedEvents.add(event)
            }
        }
    }
}
