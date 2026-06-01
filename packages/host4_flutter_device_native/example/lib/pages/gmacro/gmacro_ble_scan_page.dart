import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_ble/host4_flutter_ble.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';

import 'package:host4_flutter_log/host4_flutter_log.dart';

import 'gmacro_session_page.dart';

class GmacroBleScanPage extends StatefulWidget {
  const GmacroBleScanPage({super.key});

  @override
  State<GmacroBleScanPage> createState() => _GmacroBleScanPageState();
}

class _GmacroBleScanPageState extends State<GmacroBleScanPage> {
  final Host4Logger _log = Host4Logger('GMacroScan');
  final Host4Ble _ble = Host4Ble();
  final Host4FlutterDeviceNative _deviceNative = Host4FlutterDeviceNative();
  late final DeviceDiscovery _discovery = _ble.discovery();
  final Map<String, DeviceDescriptor> _devicesById =
      <String, DeviceDescriptor>{};

  StreamSubscription<DeviceDescriptor>? _scanSubscription;
  bool _isScanning = false;
  String? _scanError;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    unawaited(_startScan(resetDevices: true));
  }

  @override
  void dispose() {
    unawaited(_stopScan());
    super.dispose();
  }

  Future<void> _startScan({required bool resetDevices}) async {
    await _stopScan();

    if (!mounted) {
      return;
    }

    if (!kIsWeb && Platform.isAndroid) {
      final bool granted = await _deviceNative.ensureBleScanPermissions();
      if (!granted) {
        _log.warn('Need BLE and Location permissions to scan.');
        setState(() {
          _scanError = '需要蓝牙和定位权限才能扫描，请在系统设置中允许后重试。';
          _isScanning = false;
        });
        return;
      }
    }

    setState(() {
      if (resetDevices) {
        _devicesById.clear();
      }
      _isScanning = true;
      _scanError = null;
    });

    _log.info('Starting scan...');
    _scanSubscription = _discovery
        .scan(const DeviceScanQuery(serviceIds: <String>[]))
        .listen(
          (DeviceDescriptor device) {
            _log.debug('Device discovered: ${device.name} (${device.id})');
            if (!mounted) {
              return;
            }

            setState(() {
              _devicesById[device.id] = device;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            _log.error('Scan error', error: error, stackTrace: stackTrace);
            if (!mounted) {
              return;
            }

            setState(() {
              _scanError = error.toString();
              _isScanning = false;
            });
          },
        );
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _discovery.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(DeviceDescriptor device) async {
    _log.info('Connecting to device: ${device.name} (${device.id})');
    setState(() {
      _connectingDeviceId = device.id;
      _scanError = null;
    });

    await _stopScan();

    try {
      final TransportSession transport = await _ble.connect(device);
      _log.info('Successfully connected to device: ${device.id}');
      if (!mounted) {
        await transport.disconnect();
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GmacroSessionPage(transport: transport),
        ),
      );
    } catch (error, stackTrace) {
      _log.error('Connection failed for ${device.id}', error: error, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _scanError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _connectingDeviceId = null;
        });
        unawaited(_startScan(resetDevices: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DeviceDescriptor> devices = _devicesById.values.toList()
      ..sort(
        (DeviceDescriptor a, DeviceDescriptor b) => a.name.compareTo(b.name),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GMacro BLE 扫描'),
        actions: <Widget>[
          IconButton(
            tooltip: '重新扫描',
            onPressed: () => unawaited(_startScan(resetDevices: true)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _InfoBanner(
              icon: _isScanning ? Icons.radar : Icons.info_outline,
              title: _isScanning ? '正在全量扫描 BLE 设备' : '扫描已停止',
              message:
                  '当前使用 DeviceScanQuery(serviceIds: [])。如果目标设备未出现，再补真实的 GMacro Service UUID。',
            ),
          ),
          if (_scanError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _InfoBanner(
                icon: Icons.error_outline,
                title: '扫描/连接异常',
                message: _scanError!,
                tone: _BannerTone.error,
              ),
            ),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text('暂未发现设备，请确认设备已开机且可广播。'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final DeviceDescriptor device = devices[index];
                      final bool isConnecting =
                          _connectingDeviceId == device.id;
                      final Object? rssi = device.metadata['rssi'];
                      final String subtitle = [
                        if (device.name.isEmpty) '未命名设备',
                        'ID: ${device.id}',
                        if (rssi != null) 'RSSI: $rssi',
                      ].join('\n');

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            device.name.isEmpty
                                ? 'Unknown Device'
                                : device.name,
                          ),
                          subtitle: Text(subtitle),
                          trailing: FilledButton(
                            onPressed: isConnecting
                                ? null
                                : () => _connectToDevice(device),
                            child: Text(isConnecting ? '连接中' : '连接'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    this.tone = _BannerTone.info,
  });

  final IconData icon;
  final String title;
  final String message;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = switch (tone) {
      _BannerTone.info => colorScheme.primaryContainer,
      _BannerTone.error => colorScheme.errorContainer,
    };
    final Color foreground = switch (tone) {
      _BannerTone.info => colorScheme.onPrimaryContainer,
      _BannerTone.error => colorScheme.onErrorContainer,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BannerTone { info, error }
