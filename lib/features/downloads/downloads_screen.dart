import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_cubit.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_state.dart';
import 'package:zad_mobile/features/library/audio_player_screen.dart';
import 'package:zad_mobile/features/library/video_player_screen.dart';
import 'package:zad_mobile/features/library/pdf_helper.dart';
import 'package:zad_mobile/features/settings/settings_screen.dart';
import 'package:zad_mobile/shared/services/share_service.dart';
import 'package:zad_mobile/shared/services/review_service.dart';

/// Full-page Downloads screen used as a Navigation tab.
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _expandedSemester;
  String? _expandedCourse;

  @override
  void initState() {
    super.initState();
    ReviewService.triggerInAppReview();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<DownloadsCubit, DownloadsState>(
      listener: (context, state) {
        final completedCount = state.allDownloads
            .where((d) => d.status == DownloadStatus.complete)
            .length;
        if (completedCount >= 3) {
          ReviewService.triggerInAppReview();
        }
      },
      builder: (context, state) {
        final grouped = state.groupedDownloads;
        final maxGb = state.maxStorageGb;
        final storageUsedMb = state.storageUsedMb;
        final usedPercent = state.usedPercentage;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppConstants.bgLight,
            appBar: AppBar(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              title: const Row(
                children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'إدارة التنزيلات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'شارك التطبيق',
                  onPressed: () => ShareService.shareApp(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'الإعدادات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        context.read<DownloadsCubit>().loadDownloads();
                      }
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Storage usage bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المساحة المستخدمة: ${StorageService.instance.formatStorageUsed(storageUsedMb)}',
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
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usedPercent,
                          minHeight: 6,
                          backgroundColor:
                              AppConstants.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usedPercent > 0.9
                                ? Colors.red.shade600
                                : AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppConstants.dividerColor),

                // Content list
                Expanded(
                  child: grouped.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: grouped.length,
                          itemBuilder: (ctx, index) {
                            final semester = grouped.keys.elementAt(index);
                            final courses = grouped[semester]!;
                            return _buildSemesterTile(semester, courses);
                          },
                        ),
                ),
              ],
            ),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download_outlined,
              size: 52,
              color: AppConstants.textMuted.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد تنزيلات بعد',
            style: TextStyle(
              color: AppConstants.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
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
        InkWell(
          onTap: () {
            setState(() {
              _expandedSemester = isExpanded ? null : semester;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppConstants.surfaceVariant,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppConstants.primaryColor,
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
                          color: AppConstants.textDark,
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
                IconButton(
                  onPressed: () => _confirmDeleteSemester(semester),
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.red.shade400,
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
        const Divider(height: 1, color: AppConstants.dividerColor),

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                .copyWith(right: 32),
            color: Colors.white,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withValues(alpha: 0.12),
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
                      color: AppConstants.textDark,
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
                IconButton(
                  onPressed: () => _confirmDeleteCourse(semester, course),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
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
        const Divider(height: 1, color: AppConstants.dividerColor),

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
        color: Colors.red.shade50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Icon(Icons.delete_rounded, color: Colors.red.shade400),
      ),
      onDismissed: (_) async {
        await context.read<DownloadsCubit>().deleteDownload(item.id);
      },
      child: Container(
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16)
              .copyWith(right: 56),
          leading: _getFileIcon(item.category),
          title: Text(
            item.title,
            style: const TextStyle(
              color: AppConstants.textDark,
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
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.progress / 100,
                        minHeight: 4,
                        backgroundColor: AppConstants.dividerColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          trailing: _getStatusIcon(item),
          onTap: () => _openFile(item),
          onLongPress: item.category == FileCategory.pdf && item.status == DownloadStatus.complete
              ? () => PdfHelper.openPdf(context, filePath: item.localPath, title: item.title, forceAsk: true)
              : null,
        ),
      ),
    );
  }

  Widget _getFileIcon(FileCategory category) {
    IconData icon;
    Color color;
    switch (category) {
      case FileCategory.video:
        icon = Icons.videocam_rounded;
        color = Colors.blue.shade600;
        break;
      case FileCategory.audio:
        icon = Icons.headphones_rounded;
        color = Colors.orange.shade700;
        break;
      case FileCategory.pdf:
        icon = Icons.picture_as_pdf_rounded;
        color = Colors.red.shade600;
        break;
      case FileCategory.youtube:
        icon = Icons.play_circle_filled;
        color = Colors.red.shade700;
        break;
      case FileCategory.document:
        icon = Icons.description_rounded;
        color = Colors.teal.shade600;
        break;
      case FileCategory.other:
        icon = Icons.insert_drive_file_rounded;
        color = AppConstants.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
          color: AppConstants.primaryColor,
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
            await context.read<DownloadsCubit>().retryDownload(item.taskId);
          },
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.red.shade400,
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
              AppConstants.primaryColor,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _openFile(DownloadItem item) async {
    if (item.status != DownloadStatus.complete) return;

    switch (item.category) {
      case FileCategory.audio:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              filePath: item.localPath,
              title: item.title,
            ),
          ),
        );
        break;

      case FileCategory.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              filePath: item.localPath,
              title: item.title,
            ),
          ),
        );
        break;

      case FileCategory.youtube:
        if (item.youtubeVideoId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                youtubeVideoId: item.youtubeVideoId,
                title: item.title,
              ),
            ),
          );
        }
        break;

      case FileCategory.pdf:
        await PdfHelper.openPdf(
          context,
          filePath: item.localPath,
          title: item.title,
        );
        break;

      case FileCategory.document:
      case FileCategory.other:
        final file = File(item.localPath);
        if (!file.existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('الملف غير موجود:\n${item.localPath}'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
          return;
        }
        final result = await OpenFilex.open(item.localPath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر فتح الملف: ${result.message}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        break;
    }
  }

  void _confirmDeleteSemester(String semester) {
    _showDeleteDialog(
      'حذف $semester',
      'سيتم حذف جميع الملفات المحملة لهذا السمستر نهائياً. متأكد؟',
      () async {
        await context.read<DownloadsCubit>().deleteSemester(semester);
      },
    );
  }

  void _confirmDeleteCourse(String semester, String course) {
    _showDeleteDialog(
      'حذف $course',
      'سيتم حذف جميع ملفات هذا المقرر نهائياً. متأكد؟',
      () async {
        await context.read<DownloadsCubit>().deleteCourse(semester, course);
      },
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppConstants.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(color: AppConstants.textDark),
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
                backgroundColor: Colors.red.shade600,
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

// Keep the old DownloadsScreen as alias for any remaining bottom-sheet usages
// ignore: unused_element
typedef DownloadsScreen = DownloadsPage;
