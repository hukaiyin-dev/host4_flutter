package com.host4.host4_flutter_device_native

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Buffers events until the first listener attaches, then fans out to every active sink.
 *
 * Flutter may call [onListen] more than once when Dart opens multiple subscriptions on
 * the same channel name; a single [EventSink] field would drop earlier listeners.
 */
internal class QueuedEventStreamHandler : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val eventSinks = linkedSetOf<EventChannel.EventSink>()
    private val bufferedEvents = mutableListOf<Map<String, Any?>>()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) {
            return
        }
        synchronized(this) {
            eventSinks.add(events)
            val pending = bufferedEvents.toList()
            bufferedEvents.clear()
            pending.forEach { event -> events.success(event) }
        }
    }

    override fun onCancel(arguments: Any?) {
        synchronized(this) {
            eventSinks.clear()
        }
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            synchronized(this) {
                if (eventSinks.isEmpty()) {
                    bufferedEvents.add(event)
                    return@post
                }
                val sinks = eventSinks.toList()
                sinks.forEach { sink ->
                    runCatching { sink.success(event) }
                }
            }
        }
    }
}
