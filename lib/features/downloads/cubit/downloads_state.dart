import 'package:zad_mobile/features/downloads/download_model.dart';

enum DownloadsStatus { initial, loading, success, failure }

class DownloadsState {
  final DownloadsStatus status;
  final List<DownloadItem> allDownloads;
  final Map<String, Map<String, Map<String, List<DownloadItem>>>> groupedDownloads;
  final List<DownloadItem> activeDownloads;
  final double storageUsedMb;
  final double maxStorageGb;
  final String? errorMessage;

  const DownloadsState({
    this.status = DownloadsStatus.initial,
    this.allDownloads = const [],
    this.groupedDownloads = const {},
    this.activeDownloads = const [],
    this.storageUsedMb = 0.0,
    this.maxStorageGb = 2.0,
    this.errorMessage,
  });

  DownloadsState copyWith({
    DownloadsStatus? status,
    List<DownloadItem>? allDownloads,
    Map<String, Map<String, Map<String, List<DownloadItem>>>>? groupedDownloads,
    List<DownloadItem>? activeDownloads,
    double? storageUsedMb,
    double? maxStorageGb,
    String? errorMessage,
  }) {
    return DownloadsState(
      status: status ?? this.status,
      allDownloads: allDownloads ?? this.allDownloads,
      groupedDownloads: groupedDownloads ?? this.groupedDownloads,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
      maxStorageGb: maxStorageGb ?? this.maxStorageGb,
      errorMessage: errorMessage,
    );
  }

  double get usedPercentage {
    if (maxStorageGb <= 0) return 0.0;
    return (storageUsedMb / (maxStorageGb * 1024)).clamp(0.0, 1.0);
  }
}
