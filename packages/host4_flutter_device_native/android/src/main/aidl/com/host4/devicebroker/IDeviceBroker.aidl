package com.host4.devicebroker;

import com.host4.devicebroker.IDeviceBrokerCallback;
import com.host4.devicebroker.IDeviceResultCallback;
import android.os.ParcelFileDescriptor;

interface IDeviceBroker {
    android.os.Bundle getState();
    void openSession(String clientId, IDeviceBrokerCallback callback);
    void closeSession(String clientId);
    oneway void invoke(
        long requestId,
        String method,
        in android.os.Bundle arguments,
        IDeviceResultCallback callback
    );
    oneway void startOta(
        long requestId,
        in ParcelFileDescriptor firmware,
        long byteCount,
        IDeviceResultCallback callback
    );
    oneway void cancelOta(long requestId);
}
