import 'package:flutter/material.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/library/library_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String? _expandedSemester;
  String? _expandedCourse;
  double _storageUsedMb = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final used = await StorageService.instance.getTotalStorageUsedMb();
    if (mounted) {
      setState(() => _storageUsedMb = used);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = StorageService.instance.getGroupedDownloads();
    final maxGb = StorageService.instance.getMaxStorageGb();
    final usedPercent = _storageUsedMb / (maxGb * 1024);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppConstants.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.download_rounded,
                      color: AppConstants.secondaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'إدارة التنزيلات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textLight,
                        ),
                      ),
                    ),
                    // Open full library
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.open_in_full_rounded,
                        color: AppConstants.primaryLight,
                      ),
                      tooltip: 'المكتبة الكاملة',
                    ),
                  ],
                ),
              ),

              // Storage usage bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المساحة المستخدمة: ${StorageService.instance.formatStorageUsed(_storageUsedMb)}',
                          style: const TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'الحد: ${maxGb.toStringAsFixed(0)} ج.ب',
                          style: const TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usedPercent.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor:
                            AppConstants.textMuted.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          usedPercent > 0.9
                              ? Colors.redAccent
                              : AppConstants.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(
                color: AppConstants.cardDark,
                height: 1,
              ),

              // Content
              Expanded(
                child: grouped.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final semester = grouped.keys.elementAt(index);
                          final courses = grouped[semester]!;
                          return _buildSemesterTile(
                            semester,
                            courses,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 64,
            color: AppConstants.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد تنزيلات بعد',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بتحميل ملفات المقررات من المنصة',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTile(
    String semester,
    Map<String, Map<String, List<DownloadItem>>> courses,
  ) {
    final isExpanded = _expandedSemester == semester;
    final totalFiles = courses.values
        .expand((c) => c.values.expand((w) => w))
        .length;

    return Column(
      children: [
        // Semester header
        InkWell(
          onTap: () {
            setState(() {
              _expandedSemester = isExpanded ? null : semester;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppConstants.cardDark.withValues(alpha: 0.5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppConstants.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semester,
                        style: const TextStyle(
                          color: AppConstants.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$totalFiles ملف • ${courses.length} مقرر',
                        style: const TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete semester
                IconButton(
                  onPressed: () => _confirmDeleteSemester(semester),
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'حذف السمستر',
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppConstants.textMuted,
                ),
              ],
            ),
          ),
        ),

        // Courses under semester
        if (isExpanded)
          ...courses.entries.map((courseEntry) {
            return _buildCourseTile(
              semester,
              courseEntry.key,
              courseEntry.value,
            );
          }),
      ],
    );
  }

  Widget _buildCourseTile(
    String semester,
    String course,
    Map<String, List<DownloadItem>> weeks,
  ) {
    final isExpanded = _expandedCourse == '$semester/$course';
    final totalFiles = weeks.values.expand((w) => w).length;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCourse = isExpanded ? null : '$semester/$course';
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    .copyWith(right: 32),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppConstants.secondaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    course,
                    style: const TextStyle(
                      color: AppConstants.textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$totalFiles',
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
                // Delete course
                IconButton(
                  onPressed: () => _confirmDeleteCourse(semester, course),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  tooltip: 'حذف المقرر',
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppConstants.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Files under course-week
        if (isExpanded)
          ...weeks.entries.expand((weekEntry) {
            return weekEntry.value.map((item) => _buildFileTile(item));
          }),
      ],
    );
  }

  Widget _buildFileTile(DownloadItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent.withValues(alpha: 0.2),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) async {
        await StorageService.instance.deleteDownload(item.id);
        _loadStorageInfo();
        setState(() {});
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16)
            .copyWith(right: 56),
        leading: _getFileIcon(item.category),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppConstants.textLight,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              item.week,
              style: const TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            if (item.status == DownloadStatus.complete)
              Text(
                item.formattedSize,
                style: const TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 11,
                ),
              ),
            if (item.status == DownloadStatus.running)
              Expanded(
                child: LinearProgressIndicator(
                  value: item.progress / 100,
                  minHeight: 3,
                  backgroundColor:
                      AppConstants.textMuted.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryLight,
                  ),
                ),
              ),
          ],
        ),
        trailing: _getStatusIcon(item),
        onTap: () => _openFile(item),
      ),
    );
  }

  Widget _getFileIcon(FileCategory category) {
    IconData icon;
    Color color;
    switch (category) {
      case FileCategory.video:
        icon = Icons.videocam_rounded;
        color = Colors.blueAccent;
        break;
      case FileCategory.audio:
        icon = Icons.headphones_rounded;
        color = Colors.orangeAccent;
        break;
      case FileCategory.pdf:
        icon = Icons.picture_as_pdf_rounded;
        color = Colors.redAccent;
        break;
      case FileCategory.youtube:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case FileCategory.document:
        icon = Icons.description_rounded;
        color = Colors.tealAccent;
        break;
      case FileCategory.other:
        icon = Icons.insert_drive_file_rounded;
        color = AppConstants.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _getStatusIcon(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.complete:
        return const Icon(
          Icons.check_circle_rounded,
          color: AppConstants.primaryLight,
          size: 20,
        );
      case DownloadStatus.running:
        return Text(
          '${item.progress}%',
          style: const TextStyle(
            color: AppConstants.secondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      case DownloadStatus.failed:
        return IconButton(
          onPressed: () async {
            await DownloadManager.instance.retryDownload(item.taskId);
            setState(() {});
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
        );
      case DownloadStatus.enqueued:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.primaryLight,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _openFile(DownloadItem item) {
    if (item.status != DownloadStatus.complete) return;

    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryScreen(initialFile: item),
      ),
    );
  }

  void _confirmDeleteSemester(String semester) {
    _showDeleteDialog(
      'حذف $semester',
      'سيتم حذف جميع الملفات المحملة لهذا السمستر نهائياً. متأكد؟',
      () async {
        await StorageService.instance.deleteSemester(semester);
        _loadStorageInfo();
        setState(() {});
      },
    );
  }

  void _confirmDeleteCourse(String semester, String course) {
    _showDeleteDialog(
      'حذف $course',
      'سيتم حذف جميع ملفات هذا المقرر نهائياً. متأكد؟',
      () async {
        await StorageService.instance.deleteCourse(semester, course);
        _loadStorageInfo();
        setState(() {});
      },
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppConstants.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(color: AppConstants.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
