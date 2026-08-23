import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';

@pragma('vm:entry-point')
class DownloadManager {
  static DownloadManager? _instance;
  static DownloadManager get instance => _instance ??= DownloadManager._();
  DownloadManager._();

  final ReceivePort _port = ReceivePort();
  final ValueNotifier<List<DownloadItem>> activeDownloads = ValueNotifier([]);
  final StreamController<DownloadItem> _downloadUpdateController =
      StreamController<DownloadItem>.broadcast();

  Stream<DownloadItem> get downloadUpdates => _downloadUpdateController.stream;

  Future<void> init() async {
    await FlutterDownloader.initialize(debug: false, ignoreSsl: true);
    _bindBackgroundIsolate();
  }

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
    }
    _port.listen((dynamic data) {
      final taskId = data[0] as String;
      final status = data[1] as int;
      final progress = data[2] as int;
      _onDownloadProgress(taskId, status, progress);
    });
  }

  void _onDownloadProgress(String taskId, int statusInt, int progress) {
    final storage = StorageService.instance;
    final item = storage.findByTaskId(taskId);
    if (item == null) return;

    DownloadStatus newStatus;
    switch (statusInt) {
      case 1:
        newStatus = DownloadStatus.enqueued;
        break;
      case 2:
        newStatus = DownloadStatus.running;
        break;
      case 3:
        newStatus = DownloadStatus.complete;
        break;
      case 4:
        newStatus = DownloadStatus.failed;
        break;
      case 5:
        newStatus = DownloadStatus.canceled;
        break;
      case 6:
        newStatus = DownloadStatus.paused;
        break;
      default:
        newStatus = DownloadStatus.idle;
    }

    int bytes = item.totalBytes;
    if (newStatus == DownloadStatus.complete) {
      try {
        final f = File(item.localPath);
        if (f.existsSync()) {
          bytes = f.lengthSync();
        }
      } catch (_) {}
    }

    final updated = item.copyWith(
      progress: progress,
      status: newStatus,
      totalBytes: bytes > 0 ? bytes : item.totalBytes,
    );
    storage.updateDownload(updated);

    // Broadcast update to Cubit and listeners
    _downloadUpdateController.add(updated);

    // Refresh active downloads
    _refreshActiveDownloads();
  }

  void _refreshActiveDownloads() {
    final all = StorageService.instance.getAllDownloads();
    activeDownloads.value = all
        .where((d) =>
            d.status == DownloadStatus.running ||
            d.status == DownloadStatus.enqueued)
        .toList();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  /// Start downloading a file
  Future<void> startDownload({
    required String url,
    required String fileName,
    String semester = 'عام',
    String course = 'المقرر_العام',
    String week = 'ملفات',
    String? title,
  }) async {
    final storage = StorageService.instance;

    // Check if already downloaded
    final existing = storage.getAllDownloads().where((d) => d.url == url).toList();
    if (existing.isNotEmpty && existing.first.status == DownloadStatus.complete) {
      return; // Already downloaded
    }

    // Clean up file name
    final cleanFileName = _sanitizeFileName(fileName);
    final category = DownloadItem.detectCategory(url, cleanFileName);

    // YouTube links → save as bookmark
    if (category == FileCategory.youtube) {
      await _saveYouTubeBookmark(
        url: url,
        title: title ?? cleanFileName,
        semester: semester,
        course: course,
        week: week,
      );
      return;
    }

    // Get the directory path
    final filePath = await storage.getFilePath(semester, course, week, cleanFileName);

    // Create download item in DB first
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = DownloadItem(
      id: id,
      taskId: '', // will be set after enqueue
      url: url,
      title: title ?? cleanFileName,
      fileName: cleanFileName,
      localPath: filePath,
      semester: semester,
      course: course,
      week: week,
      category: category,
      createdAt: DateTime.now(),
      status: DownloadStatus.enqueued,
    );

    // Get the week directory
    final weekDir = await storage.getWeekDir(semester, course, week);

    // Enqueue download
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: weekDir.path,
      fileName: cleanFileName,
      showNotification: true,
      openFileFromNotification: false,
      headers: {
        'User-Agent': 'ZadAcademy-App/1.0',
      },
    );

    if (taskId != null) {
      final updatedItem = item.copyWith(taskId: taskId);
      await storage.saveDownload(updatedItem);
      _downloadUpdateController.add(updatedItem);
      _refreshActiveDownloads();
    }
  }

  Future<void> _saveYouTubeBookmark({
    required String url,
    required String title,
    required String semester,
    required String course,
    required String week,
  }) async {
    final storage = StorageService.instance;
    final videoId = JsBridgeHelper.extractYouTubeVideoId(url);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final item = DownloadItem(
      id: id,
      taskId: 'youtube_bookmark',
      url: url,
      title: title,
      fileName: 'youtube_$videoId',
      localPath: '',
      semester: semester,
      course: course,
      week: week,
      category: FileCategory.youtube,
      createdAt: DateTime.now(),
      status: DownloadStatus.complete,
      youtubeVideoId: videoId,
    );

    await storage.saveDownload(item);
    _downloadUpdateController.add(item);
    _refreshActiveDownloads();
  }

  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  Future<void> retryDownload(String taskId) async {
    final newTaskId = await FlutterDownloader.retry(taskId: taskId);
    if (newTaskId != null) {
      // Update stored item with new task ID
      final storage = StorageService.instance;
      final item = storage.findByTaskId(taskId);
      if (item != null) {
        final updated = item.copyWith(taskId: newTaskId, status: DownloadStatus.enqueued, progress: 0);
        await storage.updateDownload(updated);
        _downloadUpdateController.add(updated);
      }
    }
  }

  String _sanitizeFileName(String name) {
    // Remove query parameters
    var clean = name.split('?').first;
    // Remove path segments
    clean = clean.split('/').last;
    // Remove illegal characters
    clean = clean.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Ensure non-empty
    if (clean.isEmpty) {
      clean = 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
    _downloadUpdateController.close();
  }
}

/// Helper class to avoid circular import with js_bridge.dart
class JsBridgeHelper {
  static String? extractYouTubeVideoId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}
