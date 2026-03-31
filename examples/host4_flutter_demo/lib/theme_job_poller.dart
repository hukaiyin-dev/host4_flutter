import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'theme_job.dart';

/// Polls the server for in-progress jobs while the app is in the foreground.
/// Notifies listeners when any job state changes.
class ThemeJobPoller {
  ThemeJobPoller._();
  static final ThemeJobPoller instance = ThemeJobPoller._();

  Timer? _timer;
  final _listeners = <VoidCallback>[];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reconcile() {
    final hasInProgress = ThemeJobStore.instance.records.any(
      (r) => r.status.isInProgress,
    );
    if (hasInProgress) {
      start();
    } else {
      stop();
    }
  }

  Future<void> pollNow() {
    start();
    return _poll();
  }

  Future<void> _poll() async {
    final store = ThemeJobStore.instance;
    final pending = store.records.where((r) => r.status.isInProgress).toList();
    if (pending.isEmpty) {
      stop();
      return;
    }

    var changed = false;
    for (final record in pending) {
      try {
        final uri = Uri.parse('${record.serverUrl}/job/${record.jobId}');
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) continue;

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newStatus = ThemeJobStatusX.fromRaw(
          body['status'] as String? ?? '',
        );

        if (newStatus != record.status) {
          record.status = newStatus;
          if (body['tokens'] != null) {
            record.tokens = body['tokens'] as Map<String, dynamic>;
          }
          if (body['image_urls'] != null) {
            record.imageUrls = (body['image_urls'] as Map<String, dynamic>)
                .cast<String, String>();
          }
          if (body['error'] != null) {
            record.error = body['error'] as String;
          }
          if (newStatus.isTerminal) record.isRead = false;
          await store.update(record);
          changed = true;
        }
      } catch (_) {
        // Network errors during polling are silently ignored
      }
    }
    reconcile();
    if (changed) _notify();
  }

  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }
}

typedef VoidCallback = void Function();
