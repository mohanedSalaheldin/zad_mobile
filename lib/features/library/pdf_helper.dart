import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/library/pdf_reader_screen.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/shared/services/review_service.dart';

class PdfHelper {
  /// Opens a PDF file according to user preference:
  /// - 'system' (default): opens using the system default app (OpenFilex)
  /// - 'internal': opens using in-app PdfReaderScreen
  /// - 'ask': prompts the user via a bottom sheet to choose how to open
  static Future<void> openPdf(
    BuildContext context, {
    required String filePath,
    required String title,
    bool forceAsk = false,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الملف غير موجود في المسار:\n$filePath'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final pref = StorageService.instance.getPdfViewerPreference();

    if (forceAsk || pref == 'ask') {
      if (context.mounted) {
        await _showViewerChoiceModal(context, filePath: filePath, title: title);
      }
      return;
    }

    ReviewService.triggerInAppReview();
    if (pref == 'internal') {
      _openInternal(context, filePath: filePath, title: title);
    } else {
      // Default: 'system'
      await _openSystem(context, filePath: filePath, title: title);
    }
  }

  static Future<void> _openSystem(
    BuildContext context, {
    required String filePath,
    required String title,
  }) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح الملف عبر تطبيق النظام: ${result.message}'),
          backgroundColor: Colors.orange.shade800,
          action: SnackBarAction(
            label: 'فتح داخلياً',
            textColor: Colors.white,
            onPressed: () {
              _openInternal(context, filePath: filePath, title: title);
            },
          ),
        ),
      );
    }
  }

  static void _openInternal(
    BuildContext context, {
    required String filePath,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          filePath: filePath,
          title: title,
        ),
      ),
    );
  }

  static Future<void> _showViewerChoiceModal(
    BuildContext context, {
    required String filePath,
    required String title,
  }) async {
    bool rememberChoice = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: const BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppConstants.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'اختيار مشغل PDF',
                                style: TextStyle(
                                  color: AppConstants.textLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppConstants.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Option 1: System Default Viewer
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppConstants.dividerColor),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.open_in_new_rounded,
                          color: AppConstants.secondaryColor,
                        ),
                      ),
                      title: const Text(
                        'مشغل النظام الافتراضي (مستحسن)',
                        style: TextStyle(
                          color: AppConstants.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'فتح عبر تطبيق الهاتف (Drive, Adobe Reader, إلخ)',
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        if (rememberChoice) {
                          await StorageService.instance.setPdfViewerPreference('system');
                        }
                        if (context.mounted) {
                          await _openSystem(context, filePath: filePath, title: title);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Option 2: Built-in PDF reader
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppConstants.dividerColor),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chrome_reader_mode_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: const Text(
                        'قارئ التطبيق المدمج',
                        style: TextStyle(
                          color: AppConstants.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'عرض المستند مباشرة داخل تطبيق زاد',
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        if (rememberChoice) {
                          await StorageService.instance.setPdfViewerPreference('internal');
                        }
                        if (context.mounted) {
                          _openInternal(context, filePath: filePath, title: title);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Remember Choice Checkbox
                    CheckboxListTile(
                      value: rememberChoice,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppConstants.primaryColor,
                      title: const Text(
                        'تذكر خياري كافتراضي (يمكن تغييره لاحقاً من الإعدادات)',
                        style: TextStyle(
                          color: AppConstants.textLight,
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          rememberChoice = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
