import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_state.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  final StorageService _storageService;
  final DownloadManager _downloadManager;
  StreamSubscription<DownloadItem>? _downloadSubscription;

  DownloadsCubit({
    StorageService? storageService,
    DownloadManager? downloadManager,
  })  : _storageService = storageService ?? StorageService.instance,
        _downloadManager = downloadManager ?? DownloadManager.instance,
        super(const DownloadsState()) {
    _init();
  }

  void _init() {
    loadDownloads();
    _downloadSubscription = _downloadManager.downloadUpdates.listen((updatedItem) {
      _onItemUpdated(updatedItem);
    });
  }

  Future<void> loadDownloads() async {
    try {
      final all = _storageService.getAllDownloads();
      final grouped = _groupDownloads(all);
      final active = all
          .where((d) =>
              d.status == DownloadStatus.running ||
              d.status == DownloadStatus.enqueued)
          .toList();
      final usedMb = await _storageService.getTotalStorageUsedMb();
      final maxGb = _storageService.getMaxStorageGb();

      emit(state.copyWith(
        status: DownloadsStatus.success,
        allDownloads: all,
        groupedDownloads: grouped,
        activeDownloads: active,
        storageUsedMb: usedMb,
        maxStorageGb: maxGb,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DownloadsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onItemUpdated(DownloadItem updatedItem) {
    final currentList = List<DownloadItem>.from(state.allDownloads);
    final index = currentList.indexWhere((item) => item.id == updatedItem.id || (item.taskId.isNotEmpty && item.taskId == updatedItem.taskId));

    if (index != -1) {
      currentList[index] = updatedItem;
    } else {
      currentList.insert(0, updatedItem);
    }

    final grouped = _groupDownloads(currentList);
    final active = currentList
        .where((d) =>
            d.status == DownloadStatus.running ||
            d.status == DownloadStatus.enqueued)
        .toList();

    emit(state.copyWith(
      allDownloads: currentList,
      groupedDownloads: grouped,
      activeDownloads: active,
    ));

    // If completed or deleted, re-calculate storage in background
    if (updatedItem.status == DownloadStatus.complete) {
      _updateStorageUsed();
    }
  }

  Future<void> _updateStorageUsed() async {
    final usedMb = await _storageService.getTotalStorageUsedMb();
    emit(state.copyWith(storageUsedMb: usedMb));
  }

  Map<String, Map<String, Map<String, List<DownloadItem>>>> _groupDownloads(
      List<DownloadItem> all) {
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

  Future<void> deleteDownload(String id) async {
    await _storageService.deleteDownload(id);
    await loadDownloads();
  }

  Future<void> deleteSemester(String semester) async {
    await _storageService.deleteSemester(semester);
    await loadDownloads();
  }

  Future<void> deleteCourse(String semester, String course) async {
    await _storageService.deleteCourse(semester, course);
    await loadDownloads();
  }

  Future<void> retryDownload(String taskId) async {
    await _downloadManager.retryDownload(taskId);
    await loadDownloads();
  }

  Future<void> cancelDownload(String taskId) async {
    await _downloadManager.cancelDownload(taskId);
    await loadDownloads();
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
