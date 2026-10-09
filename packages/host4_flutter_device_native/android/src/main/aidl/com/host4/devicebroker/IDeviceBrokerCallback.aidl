package com.host4.devicebroker;

oneway interface IDeviceBrokerCallback {
    void onStateChanged(String state, in android.os.Bundle extras);
    void onProtocolEvent(in android.os.Bundle event);
    void onRealtimeEvent(in android.os.Bundle event);
    void onOtaEvent(in android.os.Bundle event);
}
