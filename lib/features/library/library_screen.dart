import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_cubit.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_state.dart';
import 'package:zad_mobile/features/downloads/download_model.dart';
import 'package:zad_mobile/features/library/video_player_screen.dart';
import 'package:zad_mobile/features/library/audio_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final DownloadItem? initialFile;

  const LibraryScreen({super.key, this.initialFile});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  FileCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    // If we have an initial file, open it after build
    if (widget.initialFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFile(widget.initialFile!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsCubit, DownloadsState>(
      builder: (context, state) {
        final completedFiles = state.allDownloads
            .where((d) => d.status == DownloadStatus.complete)
            .toList();

        final filteredFiles = _filterCategory == null
            ? completedFiles
            : completedFiles
                .where((f) => f.category == _filterCategory)
                .toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppConstants.bgDark,
            appBar: AppBar(
              backgroundColor: AppConstants.cardDark,
              foregroundColor: AppConstants.textLight,
              elevation: 0,
              title: const Text(
                'المكتبة المحلية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                PopupMenuButton<FileCategory?>(
                  icon: const Icon(Icons.filter_list_rounded),
                  color: AppConstants.cardDark,
                  onSelected: (category) {
                    setState(() => _filterCategory = category);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('الكل',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                    const PopupMenuItem(
                      value: FileCategory.video,
                      child: Text('فيديو',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                    const PopupMenuItem(
                      value: FileCategory.audio,
                      child: Text('صوت',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                    const PopupMenuItem(
                      value: FileCategory.pdf,
                      child: Text('PDF',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                    const PopupMenuItem(
                      value: FileCategory.youtube,
                      child: Text('يوتيوب',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                    const PopupMenuItem(
                      value: FileCategory.document,
                      child: Text('مستندات',
                          style: TextStyle(color: AppConstants.textLight)),
                    ),
                  ],
                ),
              ],
            ),
            body: filteredFiles.isEmpty
                ? _buildEmptyState()
                : _buildFileGrid(filteredFiles),
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
            Icons.folder_open_rounded,
            size: 80,
            color: AppConstants.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _filterCategory != null
                ? 'لا توجد ملفات من هذا النوع'
                : 'المكتبة فارغة',
            style: const TextStyle(
              color: AppConstants.textMuted,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'الملفات المحملة ستظهر هنا',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(List<DownloadItem> files) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = files[index];
        return _buildFileCard(item);
      },
    );
  }

  Widget _buildFileCard(DownloadItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _getFileIcon(item.category),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppConstants.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _getCategoryChip(item.category),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.formattedSize,
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${item.course} • ${item.week}',
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _openFile(item),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          onPressed: () async {
            await context.read<DownloadsCubit>().deleteDownload(item.id);
          },
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _getCategoryChip(FileCategory category) {
    String label;
    Color color;
    switch (category) {
      case FileCategory.video:
        label = 'فيديو';
        color = Colors.blueAccent;
        break;
      case FileCategory.audio:
        label = 'صوت';
        color = Colors.orangeAccent;
        break;
      case FileCategory.pdf:
        label = 'PDF';
        color = Colors.redAccent;
        break;
      case FileCategory.youtube:
        label = 'يوتيوب';
        color = Colors.red;
        break;
      case FileCategory.document:
        label = 'مستندات';
        color = Colors.tealAccent;
        break;
      case FileCategory.other:
        label = 'ملف';
        color = AppConstants.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _openFile(DownloadItem item) async {
    switch (item.category) {
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
      case FileCategory.pdf:
      case FileCategory.document:
      case FileCategory.other:
        final file = File(item.localPath);
        if (!file.existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('الملف غير موجود في المسار:\n${item.localPath}'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
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
              backgroundColor: Colors.redAccent,
            ),
          );
        }
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
    }
  }
}
