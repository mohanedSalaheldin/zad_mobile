import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  late Box<Map> _downloadsBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _downloadsBox = await Hive.openBox<Map>(AppConstants.downloadsBoxName);
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  }

  // ─── Downloads CRUD ───

  Future<void> saveDownload(DownloadItem item) async {
    await _downloadsBox.put(item.id, item.toMap());
  }

  Future<void> updateDownload(DownloadItem item) async {
    await _downloadsBox.put(item.id, item.toMap());
  }

  Future<void> deleteDownload(String id) async {
    final item = getDownload(id);
    if (item != null) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _downloadsBox.delete(id);
  }

  DownloadItem? getDownload(String id) {
    final map = _downloadsBox.get(id);
    if (map == null) return null;
    return DownloadItem.fromMap(map);
  }

  List<DownloadItem> getAllDownloads() {
    return _downloadsBox.values
        .map((m) => DownloadItem.fromMap(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<DownloadItem> getDownloadsBySemester(String semester) {
    return getAllDownloads()
        .where((d) => d.semester == semester)
        .toList();
  }

  List<DownloadItem> getDownloadsByCourse(String semester, String course) {
    return getAllDownloads()
        .where((d) => d.semester == semester && d.course == course)
        .toList();
  }

  /// Get downloads grouped: { semester: { course: { week: [items] } } }
  Map<String, Map<String, Map<String, List<DownloadItem>>>> getGroupedDownloads() {
    final all = getAllDownloads();
    final grouped = <String, Map<String, Map<String, List<DownloadItem>>>>{};

    for (final item in all) {
      grouped
          .putIfAbsent(item.semester, () => {})
          .putIfAbsent(item.course, () => {})
          .putIfAbsent(item.week, () => [])
          .add(item);
    }
    return grouped;
  }

  /// Delete all downloads for a semester
  Future<void> deleteSemester(String semester) async {
    final items = getDownloadsBySemester(semester);
    for (final item in items) {
      await deleteDownload(item.id);
    }
    // Try to delete the semester directory too
    final dir = await _getSemesterDir(semester);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Delete all downloads for a course within a semester
  Future<void> deleteCourse(String semester, String course) async {
    final items = getDownloadsByCourse(semester, course);
    for (final item in items) {
      await deleteDownload(item.id);
    }
    final dir = await _getCourseDir(semester, course);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Delete ALL downloads
  Future<void> deleteAllDownloads() async {
    final items = getAllDownloads();
    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _downloadsBox.clear();
    final baseDir = await getDownloadsBaseDir();
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
      await baseDir.create(recursive: true);
    }
  }

  // ─── File System Paths ───

  Future<Directory> getDownloadsBaseDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/ZadDownloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getSemesterDir(String semester) async {
    final baseDir = await getDownloadsBaseDir();
    return Directory('${baseDir.path}/$semester');
  }

  Future<Directory> _getCourseDir(String semester, String course) async {
    final semDir = await _getSemesterDir(semester);
    return Directory('${semDir.path}/$course');
  }

  Future<Directory> getWeekDir(String semester, String course, String week) async {
    final courseDir = await _getCourseDir(semester, course);
    final dir = Directory('${courseDir.path}/$week');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> getFilePath(String semester, String course, String week, String fileName) async {
    final weekDir = await getWeekDir(semester, course, week);
    return '${weekDir.path}/$fileName';
  }

  // ─── Storage Usage ───

  Future<double> getTotalStorageUsedMb() async {
    final baseDir = await getDownloadsBaseDir();
    if (!await baseDir.exists()) return 0;

    double totalBytes = 0;
    await for (final entity in baseDir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }

  String formatStorageUsed(double mb) {
    if (mb < 1) return '${(mb * 1024).toStringAsFixed(0)} ك.ب';
    if (mb < 1024) return '${mb.toStringAsFixed(1)} م.ب';
    return '${(mb / 1024).toStringAsFixed(2)} ج.ب';
  }

  // ─── Settings ───

  double getMaxStorageGb() {
    return _settingsBox.get('maxStorageGb', defaultValue: AppConstants.defaultMaxStorageGb) as double;
  }

  Future<void> setMaxStorageGb(double gb) async {
    await _settingsBox.put('maxStorageGb', gb);
  }

  String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'ar') as String;
  }

  Future<void> setLanguage(String lang) async {
    await _settingsBox.put('language', lang);
  }

  /// PDF Viewer preference: 'system' (default), 'internal', 'ask'
  String getPdfViewerPreference() {
    return _settingsBox.get('pdfViewerPreference', defaultValue: 'system') as String;
  }

  Future<void> setPdfViewerPreference(String pref) async {
    await _settingsBox.put('pdfViewerPreference', pref);
  }

  DownloadItem? findByTaskId(String taskId) {
    try {
      return getAllDownloads().firstWhere((d) => d.taskId == taskId);
    } catch (_) {
      return null;
    }
  }
}
