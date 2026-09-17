package com.host4.host4_flutter_device_native.broker

object DeviceBrokerContract {
    const val SERVICE_ACTION = "com.host4.devicebroker.BIND"
    const val SERVICE_CLASS_NAME = "com.host4.grymax.devicebroker.DeviceBrokerService"
    const val UART_DEVICE_ID = "__uart__"

    const val STATE_OPENING = "opening"
    const val STATE_CREATED = "created"
    const val STATE_READY = "ready"
    const val STATE_DISCONNECTED = "disconnected"
    const val STATE_RECOVERING = "recovering"
    const val STATE_ERROR = "error"
    const val STATE_STOPPED = "stopped"

    const val ERROR_DISCONNECTED = "broker-disconnected"
    const val ERROR_NOT_READY = "broker-not-ready"
    const val ERROR_OTA_BUSY = "broker-ota-busy"
    const val ERROR_OTA_CANCELLED = "broker-ota-cancelled"
}
