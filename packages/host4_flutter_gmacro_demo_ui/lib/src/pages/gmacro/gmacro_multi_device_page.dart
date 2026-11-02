import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_ble/host4_flutter_ble.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_usb/host4_flutter_usb.dart';

import 'gmacro_multi_device_session_manager.dart';
import 'gmacro_api_test_page.dart';

/// Manual USB + multi-BLE communication test for the mobile demo.
class GmacroMultiDevicePage extends StatefulWidget {
  const GmacroMultiDevicePage({super.key});

  @override
  State<GmacroMultiDevicePage> createState() => _GmacroMultiDevicePageState();
}

class _GmacroMultiDevicePageState extends State<GmacroMultiDevicePage> {
  static const _serviceIds = <String>['FF00', 'FF10'];

  final _ble = Host4Ble();
  final _usb = Host4Usb();
  final _native = Host4FlutterDeviceNative();
  final _gmacro = Host4Gmacro();
  final _devices = <String, DeviceDescriptor>{};
  late final DeviceDiscovery _discovery;
  late final GmacroMultiDeviceSessionManager _manager;
  StreamSubscription<DeviceDescriptor>? _scanSub;
  bool _scanning = false;
  bool _busy = false;
  String _result = '选择一台已就绪设备，查询版本以验证命令路由。';

  @override
  void initState() {
    super.initState();
    _discovery = _ble.discovery();
    _manager = GmacroMultiDeviceSessionManager(
      attach: _gmacro.attach,
      releaseUsb: _usb.release,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    if (_scanning) unawaited(_discovery.stop());
    _manager.removeListener(_refresh);
    unawaited(_manager.close());
    super.dispose();
  }

  Future<bool> _ensureBlePermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final granted = await _native.ensureBleScanPermissions();
    if (!granted) _message('需要蓝牙权限才能查找设备');
    return granted;
  }

  Future<void> _loadSystemDevices() async {
    if (_busy || !await _ensureBlePermissions()) return;
    setState(() => _busy = true);
    try {
      final devices = await _ble.systemConnectedDevices(_serviceIds);
      if (!mounted) return;
      setState(() {
        for (final device in devices) {
          _devices[device.id] = device;
        }
        _result = '系统已连接或已配对设备：${devices.length} 台';
      });
    } catch (error) {
      _message('读取系统设备失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startScan() async {
    if (_scanning || !await _ensureBlePermissions()) return;
    setState(() => _scanning = true);
    _scanSub = _discovery
        .scan(const DeviceScanQuery(serviceIds: []))
        .listen(
          (device) {
            if (mounted) setState(() => _devices[device.id] = device);
          },
          onError: (Object error) {
            if (mounted) setState(() => _scanning = false);
            _message('扫描失败：$error');
          },
          onDone: () {
            if (mounted) setState(() => _scanning = false);
          },
        );
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _discovery.stop();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connectUsb() async {
    if (_busy || _manager.contains(TransportKind.usb, 'usb-auto')) return;
    setState(() => _busy = true);
    try {
      final transport = await _usb.connectAuto(
        options: const {'protocolType': 'gmacro'},
      );
      if (!mounted) {
        await transport.disconnect();
        await _usb.release();
        return;
      }
      await _manager.addTransport(transport);
    } catch (error) {
      _message('USB 连接失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectBle(DeviceDescriptor device) async {
    if (_busy || _manager.contains(TransportKind.ble, device.id)) return;
    setState(() => _busy = true);
    try {
      if (_scanning) await _stopScan();
      final transport = device.metadata['systemConnected'] == true
          ? await _ble.connectSystemConnectedDevice(
              device,
              serviceIds: _serviceIds,
              options: const {'protocolType': 'gmacro'},
            )
          : await _ble.connect(
              device,
              options: const {'protocolType': 'gmacro'},
            );
      if (!mounted) {
        await transport.disconnect();
        return;
      }
      await _manager.addTransport(transport);
    } catch (error) {
      _message('BLE 连接失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _querySelected() async {
    if (_busy) return;
    final key = _manager.selectedKey;
    if (key == null) return;
    setState(() => _busy = true);
    try {
      final response = await _manager.querySelectedVersion();
      if (mounted) setState(() => _result = '$key → $response');
    } catch (error) {
      _message('查询失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    setState(() => _result = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final connections = _manager.connections;
    final devices = _devices.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      appBar: AppBar(title: const Text('GMacro 多设备通信')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('USB 可与多台 BLE 同时连接。点选已连接设备后，查询仅发送到该设备。'),
          const SizedBox(height: 12),
          if (!kIsWeb && Platform.isAndroid)
            FilledButton.icon(
              onPressed:
                  _busy || _manager.contains(TransportKind.usb, 'usb-auto')
                  ? null
                  : _connectUsb,
              icon: const Icon(Icons.usb),
              label: const Text('连接 USB'),
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _loadSystemDevices,
                child: const Text('读取系统蓝牙设备'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : (_scanning ? _stopScan : _startScan),
                child: Text(_scanning ? '停止扫描' : '扫描 BLE'),
              ),
            ],
          ),
          const Divider(),
          Text(
            '可连接 BLE（${devices.length}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final device in devices)
            ListTile(
              title: Text(device.name.isEmpty ? '未命名设备' : device.name),
              subtitle: Text(device.id),
              trailing: _manager.contains(TransportKind.ble, device.id)
                  ? const Text('已添加')
                  : TextButton(
                      onPressed: _busy ? null : () => _connectBle(device),
                      child: const Text('连接'),
                    ),
            ),
          const Divider(),
          Text(
            '已添加设备（${connections.length}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final connection in connections)
            Card(
              child: ListTile(
                selected: _manager.selectedKey == connection.key,
                onTap: () => _manager.select(connection.key),
                title: Text(
                  '${connection.transport.device.name} · ${connection.transport.device.kind.name.toUpperCase()}',
                ),
                subtitle: Text(
                  '${connection.transport.device.id}\n${connection.status}${connection.lastInput == null ? '' : '\n最近输入：${connection.lastInput}'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: '断开此设备',
                  onPressed: _busy
                      ? null
                      : () async {
                          try {
                            await _manager.remove(connection.key);
                          } catch (error) {
                            _message('断开失败：$error');
                          }
                        },
                  icon: const Icon(Icons.link_off),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _busy ||
                    !connections.any(
                      (entry) =>
                          entry.key == _manager.selectedKey &&
                          entry.session != null,
                    )
                ? null
                : _querySelected,
            child: const Text('查询选中设备版本'),
          ),
          OutlinedButton(
            onPressed: _busy || _manager.selectedSession == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GmacroApiTestPage(session: _manager.selectedSession),
                    ),
                  ),
            child: const Text('测试选中设备的完整 API'),
          ),
          const SizedBox(height: 8),
          SelectableText(_result),
        ],
      ),
    );
  }
}
