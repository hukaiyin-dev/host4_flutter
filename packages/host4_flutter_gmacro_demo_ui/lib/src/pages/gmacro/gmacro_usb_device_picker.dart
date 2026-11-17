import 'dart:async';

import 'package:flutter/material.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

Future<DeviceDescriptor?> showGmacroUsbDevicePicker(
  BuildContext context, {
  required Host4Usb usb,
}) {
  return showModalBottomSheet<DeviceDescriptor>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UsbDevicePicker(discovery: usb.discovery()),
  );
}

class _UsbDevicePicker extends StatefulWidget {
  const _UsbDevicePicker({required this.discovery});

  final DeviceDiscovery discovery;

  @override
  State<_UsbDevicePicker> createState() => _UsbDevicePickerState();
}

class _UsbDevicePickerState extends State<_UsbDevicePicker> {
  final _devices = <String, DeviceDescriptor>{};
  StreamSubscription<DeviceDescriptor>? _subscription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = widget.discovery
        .scan(const DeviceScanQuery(serviceIds: []))
        .listen(
          (device) {
            if (mounted) setState(() => _devices[device.id] = device);
          },
          onError: (Object error) {
            if (mounted) setState(() => _error = '$error');
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(widget.discovery.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            const ListTile(title: Text('选择 USB 设备')),
            Expanded(
              child: devices.isEmpty
                  ? Center(child: Text(_error ?? '正在查找已接入的 USB 设备…'))
                  : ListView(
                      children: [
                        for (final device in devices)
                          ListTile(
                            title: Text(
                              device.name.isEmpty ? '未命名 USB 设备' : device.name,
                            ),
                            subtitle: Text('VID:PID ${device.id}'),
                            onTap: () => Navigator.of(context).pop(device),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
