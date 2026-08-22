enum FileCategory {
  video,
  audio,
  pdf,
  youtube,
  document,
  other,
}

enum DownloadStatus {
  idle,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
}

class DownloadItem {
  final String id;
  final String taskId;
  final String url;
  final String title;
  final String fileName;
  final String localPath;
  final String semester;
  final String course;
  final String week;
  final int totalBytes;
  final int progress; // 0 - 100
  final DownloadStatus status;
  final FileCategory category;
  final DateTime createdAt;
  final String? youtubeVideoId;

  DownloadItem({
    required this.id,
    required this.taskId,
    required this.url,
    required this.title,
    required this.fileName,
    required this.localPath,
    required this.semester,
    required this.course,
    required this.week,
    this.totalBytes = 0,
    this.progress = 0,
    this.status = DownloadStatus.idle,
    required this.category,
    required this.createdAt,
    this.youtubeVideoId,
  });

  DownloadItem copyWith({
    String? id,
    String? taskId,
    String? url,
    String? title,
    String? fileName,
    String? localPath,
    String? semester,
    String? course,
    String? week,
    int? totalBytes,
    int? progress,
    DownloadStatus? status,
    FileCategory? category,
    DateTime? createdAt,
    String? youtubeVideoId,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      url: url ?? this.url,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      semester: semester ?? this.semester,
      course: course ?? this.course,
      week: week ?? this.week,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'url': url,
      'title': title,
      'fileName': fileName,
      'localPath': localPath,
      'semester': semester,
      'course': course,
      'week': week,
      'totalBytes': totalBytes,
      'progress': progress,
      'status': status.name,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'youtubeVideoId': youtubeVideoId,
    };
  }

  factory DownloadItem.fromMap(Map<dynamic, dynamic> map) {
    return DownloadItem(
      id: map['id']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? 'ملف تعليمي',
      fileName: map['fileName']?.toString() ?? '',
      localPath: map['localPath']?.toString() ?? '',
      semester: map['semester']?.toString() ?? 'عام',
      course: map['course']?.toString() ?? 'المقرر_العام',
      week: map['week']?.toString() ?? 'ملفات',
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.idle,
      ),
      category: FileCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FileCategory.other,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      youtubeVideoId: map['youtubeVideoId']?.toString(),
    );
  }

  static FileCategory detectCategory(String url, String fileName) {
    final lowerUrl = url.toLowerCase();
    final lowerName = fileName.toLowerCase();

    if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerName.contains('youtube')) {
      return FileCategory.youtube;
    }
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.avi')) {
      return FileCategory.video;
    }
    if (lowerName.endsWith('.mp3') ||
        lowerName.endsWith('.m4a') ||
        lowerName.endsWith('.aac') ||
        lowerName.endsWith('.wav') ||
        lowerName.endsWith('.ogg')) {
      return FileCategory.audio;
    }
    if (lowerName.endsWith('.pdf')) {
      return FileCategory.pdf;
    }
    if (lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx') ||
        lowerName.endsWith('.ppt') ||
        lowerName.endsWith('.pptx') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx') ||
        lowerName.endsWith('.txt')) {
      return FileCategory.document;
    }
    return FileCategory.other;
  }

  String get formattedSize {
    if (totalBytes <= 0) return 'حجم غير معروف';
    if (totalBytes < 1024) return '$totalBytes بايت';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} ك.ب';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} ج.ب';
  }
}
