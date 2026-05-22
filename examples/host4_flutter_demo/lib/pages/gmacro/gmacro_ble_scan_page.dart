import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:host4_flutter_ble/host4_flutter_ble.dart';
import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';
import 'package:host4_flutter_transport/host4_flutter_transport.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../../widgets/sub_page_scaffold.dart';
import 'gmacro_session_page.dart';

class GmacroBleScanPage extends StatefulWidget {
  const GmacroBleScanPage({super.key});

  @override
  State<GmacroBleScanPage> createState() => _GmacroBleScanPageState();
}

class _GmacroBleScanPageState extends State<GmacroBleScanPage> {
  final _ble = Host4Ble();
  final _deviceNative = Host4FlutterDeviceNative();
  late final DeviceDiscovery _discovery;

  // Map<id, device> 保证同一设备不重复出现（原生会持续上报 RSSI 更新）
  final _seen = <String, DeviceDescriptor>{};

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _hideUnnamed = true;
  StreamSubscription<DeviceDescriptor>? _scanSub;

  @override
  void initState() {
    super.initState();
    _discovery = _ble.discovery();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    if (_isScanning) _discovery.stop();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    if (!kIsWeb && Platform.isAndroid) {
      final bool granted = await _deviceNative.ensureBleScanPermissions();
      if (!granted) {
        _showSnack('需要蓝牙和定位权限才能扫描 BLE 设备，请在系统设置中允许后重试。');
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _seen.clear();
    });

    // serviceIds 传空列表表示扫描全部设备。
    // 生产场景建议填入 GMacro 设备的真实 Service UUID 以提高效率。
    final stream = _discovery.scan(const DeviceScanQuery(serviceIds: []));
    _scanSub = stream.listen(
      (device) {
        if (!mounted) return;
        setState(() => _seen[device.id] = device);
      },
      onError: (Object err) {
        if (!mounted) return;
        setState(() => _isScanning = false);
        _showSnack('扫描错误: $err');
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _discovery.stop();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(DeviceDescriptor device) async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    await _stopScan();

    try {
      final transport = await _ble.connect(device);
      if (!mounted) return;
      // replace 当前页，返回时直接回到 Entry
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GmacroSessionPage(transport: transport),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('连接失败: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final devices = _seen.values
        .where((d) => !_hideUnnamed || (d.name.isNotEmpty && d.name != 'Unknown'))
        .toList();

    return SubPageScaffold(
      title: 'BLE 扫描',
      subtitle: _isScanning ? '扫描中，点击设备连接…' : '共发现 ${devices.length} 台设备',
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.page,
              vertical: theme.spacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isConnecting
                        ? null
                        : (_isScanning ? _stopScan : _startScan),
                    icon: _isScanning
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colors.textInverse,
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(_isScanning ? '停止扫描' : '开始扫描'),
                  ),
                ),
                SizedBox(width: theme.spacing.sm),
                Row(
                  children: [
                    Host4Text(
                      '仅命名设备',
                      colorRole: Host4TextColorRole.secondary,
                    ),
                    Switch(
                      value: _hideUnnamed,
                      onChanged: (v) => setState(() => _hideUnnamed = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? _EmptyHint(isScanning: _isScanning)
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.page,
                    ),
                    itemCount: devices.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: theme.spacing.sm),
                    itemBuilder: (_, i) => _DeviceTile(
                      device: devices[i],
                      isConnecting:
                          _isConnecting,
                      onTap: () => _connect(devices[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScanning
                ? Icons.bluetooth_searching_rounded
                : Icons.bluetooth_disabled_rounded,
            size: 48,
            color: theme.colors.textSecondary,
          ),
          SizedBox(height: theme.spacing.md),
          Host4Text(
            isScanning ? '扫描中，请确保设备处于广播状态' : '点击"开始扫描"搜索附近设备',
            colorRole: Host4TextColorRole.secondary,
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isConnecting,
    required this.onTap,
  });

  final DeviceDescriptor device;
  final bool isConnecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final rssi = device.metadata['rssi'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.card),
        onTap: isConnecting ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(theme.radius.card),
            border: Border.all(color: theme.colors.borderDefault),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bluetooth_rounded,
                  color: theme.colors.brandPrimary,
                  size: 22,
                ),
                SizedBox(width: theme.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Host4Text(
                        device.name.isEmpty ? '未知设备' : device.name,
                        role: Host4TextRole.heading,
                      ),
                      SizedBox(height: 2),
                      Host4Text(
                        device.id,
                        colorRole: Host4TextColorRole.secondary,
                      ),
                    ],
                  ),
                ),
                if (rssi != null)
                  Text(
                    '$rssi dBm',
                    style: theme.typography.caption
                        .toTextStyle(theme.colors.textSecondary),
                  ),
                SizedBox(width: theme.spacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
