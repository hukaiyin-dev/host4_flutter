# host4_flutter_device_native references the optional FastBle implementation.
# The silicone overlay demo does not use this path, but release R8 validates it.
-dontwarn com.clj.fastble.BleManager
-dontwarn com.clj.fastble.callback.BleGattCallback
-dontwarn com.clj.fastble.callback.BleNotifyCallback
-dontwarn com.clj.fastble.callback.BleWriteCallback
-dontwarn com.clj.fastble.data.BleDevice
