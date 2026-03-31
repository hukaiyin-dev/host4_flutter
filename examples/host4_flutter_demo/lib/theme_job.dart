import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

enum ThemeJobStatus { pending, colorsDone, imagesGenerating, done, failed }

extension ThemeJobStatusX on ThemeJobStatus {
  String get rawValue => switch (this) {
        ThemeJobStatus.pending => 'pending',
        ThemeJobStatus.colorsDone => 'colors_done',
        ThemeJobStatus.imagesGenerating => 'images_generating',
        ThemeJobStatus.done => 'done',
        ThemeJobStatus.failed => 'failed',
      };

  bool get isTerminal => this == ThemeJobStatus.done || this == ThemeJobStatus.failed;
  bool get isInProgress => !isTerminal;

  static ThemeJobStatus fromRaw(String raw) => switch (raw) {
        'colors_done' => ThemeJobStatus.colorsDone,
        'images_generating' => ThemeJobStatus.imagesGenerating,
        'done' => ThemeJobStatus.done,
        'failed' => ThemeJobStatus.failed,
        _ => ThemeJobStatus.pending,
      };
}

class ThemeJobRecord {
  ThemeJobRecord({
    required this.jobId,
    required this.prompt,
    required this.serverUrl,
    required this.createdAt,
    this.generateImages = false,
    this.status = ThemeJobStatus.pending,
    this.tokens,
    this.imageUrls,
    this.localImagePaths,
    this.error,
    this.isRead = false,
  });

  final String jobId;
  final String prompt;
  final String serverUrl;
  final DateTime createdAt;
  final bool generateImages;
  ThemeJobStatus status;
  Map<String, dynamic>? tokens;
  /// Server URL map: url_key → absolute URL (e.g. "/generated/{id}/images/x.png").
  Map<String, String>? imageUrls;
  /// Local file path map: url_key → absolute local path (populated after download).
  Map<String, String>? localImagePaths;
  String? error;
  bool isRead;

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'prompt': prompt,
        'serverUrl': serverUrl,
        'createdAt': createdAt.toIso8601String(),
        'generateImages': generateImages,
        'status': status.rawValue,
        if (tokens != null) 'tokens': tokens,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (localImagePaths != null) 'localImagePaths': localImagePaths,
        if (error != null) 'error': error,
        'isRead': isRead,
      };

  factory ThemeJobRecord.fromJson(Map<String, dynamic> j) => ThemeJobRecord(
        jobId: j['jobId'] as String,
        prompt: j['prompt'] as String,
        serverUrl: j['serverUrl'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        generateImages: j['generateImages'] as bool? ?? false,
        status: ThemeJobStatusX.fromRaw(j['status'] as String? ?? 'pending'),
        tokens: j['tokens'] as Map<String, dynamic>?,
        imageUrls: (j['imageUrls'] as Map<String, dynamic>?)?.cast<String, String>(),
        localImagePaths: (j['localImagePaths'] as Map<String, dynamic>?)?.cast<String, String>(),
        error: j['error'] as String?,
        isRead: j['isRead'] as bool? ?? false,
      );
}

// ── Store ──────────────────────────────────────────────────────────────────────

class ThemeJobStore {
  ThemeJobStore._();
  static final ThemeJobStore instance = ThemeJobStore._();

  List<ThemeJobRecord> _records = [];
  bool _loaded = false;

  List<ThemeJobRecord> get records => List.unmodifiable(_records);

  bool get hasUnread => _records.any((r) => r.status.isTerminal && !r.isRead);

  Future<void> load() async {
    if (_loaded) return;
    final file = await _indexFile();
    if (await file.exists()) {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      _records = list
          .map((e) => ThemeJobRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _loaded = true;
  }

  Future<void> add(ThemeJobRecord record) async {
    _records.insert(0, record);
    await _save();
  }

  Future<void> update(ThemeJobRecord record) async {
    final idx = _records.indexWhere((r) => r.jobId == record.jobId);
    if (idx != -1) {
      _records[idx] = record;
      await _save();
    }
  }

  Future<void> delete(String jobId) async {
    _records.removeWhere((r) => r.jobId == jobId);
    await _save();
    // Delete tokens file if it exists
    final dir = await _jobDir(jobId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> clear() async {
    _records = [];
    await _save();
    final dir = await _baseDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> markAllRead() async {
    for (final r in _records) {
      r.isRead = true;
    }
    await _save();
  }

  Future<void> _save() async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(_records.map((r) => r.toJson()).toList()));
  }

  Future<File> _indexFile() async {
    final dir = await _baseDir();
    return File('${dir.path}/index.json');
  }

  Future<Directory> _jobDir(String jobId) async {
    final dir = await _baseDir();
    return Directory('${dir.path}/$jobId');
  }

  Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/generated_themes');
    await dir.create(recursive: true);
    return dir;
  }
}
