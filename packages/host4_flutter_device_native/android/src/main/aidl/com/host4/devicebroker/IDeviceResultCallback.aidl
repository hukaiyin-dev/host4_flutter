package com.host4.devicebroker;

oneway interface IDeviceResultCallback {
    void onResult(
        long requestId,
        int statusCode,
        String errorCode,
        String message,
        in android.os.Bundle payload
    );
}
