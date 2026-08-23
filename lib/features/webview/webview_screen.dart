import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/widgets/loading_indicator.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_cubit.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_state.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/downloads/downloads_screen.dart';
import 'package:zad_mobile/features/settings/settings_screen.dart';
import 'package:zad_mobile/features/webview/js_bridge.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String _currentSemester = 'عام';
  String _currentCourse = 'المقرر_العام';
  String _currentWeek = 'ملفات';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_webViewController != null &&
            await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(AppConstants.loginUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  userAgent: AppConstants.customUserAgent,
                  supportZoom: true,
                  transparentBackground: false,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  allowContentAccess: true,
                  allowFileAccess: true,
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  // Register JS handler for bridge ready callback
                  controller.addJavaScriptHandler(
                    handlerName: 'onBridgeReady',
                    callback: (args) {
                      debugPrint('ZadBridge: JS bridge ready');
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                    _progress = 0;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                    _progress = 1.0;
                  });
                  // Inject JS bridge
                  await controller.evaluateJavascript(
                    source: JsBridge.contextExtractionScript,
                  );
                  // Extract course context
                  await _updateCourseContext();
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                    _isLoading = progress < 100;
                  });
                },
                onDownloadStartRequest: (controller, request) async {
                  final url = request.url.toString();
                  final fileName = request.suggestedFilename ??
                      url.split('/').last.split('?').first;

                  debugPrint('ZadBridge: Download request: $url → $fileName');

                  await DownloadManager.instance.startDownload(
                    url: url,
                    fileName: fileName,
                    semester: _currentSemester,
                    course: _currentCourse,
                    week: _currentWeek,
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'جاري تحميل: $fileName',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'المكتبة',
                        textColor: AppConstants.secondaryColor,
                        onPressed: () => _showDownloadsSheet(),
                      ),
                    ),
                  );
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';

                  // Handle YouTube links — save as bookmark
                  if (JsBridge.isYouTubeUrl(url)) {
                    await DownloadManager.instance.startDownload(
                      url: url,
                      fileName: 'youtube_${JsBridge.extractYouTubeVideoId(url)}',
                      semester: _currentSemester,
                      course: _currentCourse,
                      week: _currentWeek,
                      title: 'فيديو يوتيوب',
                    );
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Handle downloadable files
                  if (JsBridge.isDownloadableUrl(url)) {
                    final fileName = url.split('/').last.split('?').first;
                    await DownloadManager.instance.startDownload(
                      url: url,
                      fileName: fileName,
                      semester: _currentSemester,
                      course: _currentCourse,
                      week: _currentWeek,
                    );
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Allow normal navigation within zad-academy.com
                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('ZadBridge: WebView error: ${error.description}');
                },
              ),

              // Loading indicator at top
              ZadLoadingIndicator(
                isLoading: _isLoading,
                progress: _progress,
              ),

              // Floating library button
              Positioned(
                bottom: 24,
                left: 16,
                child: BlocBuilder<DownloadsCubit, DownloadsState>(
                  builder: (context, state) {
                    return _buildFloatingButton(state.activeDownloads.length);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton(int activeCount) {
    return GestureDetector(
      onTap: _showDownloadsSheet,
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 28,
            ),
            if (activeCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCourseContext() async {
    if (_webViewController == null) return;
    try {
      final result = await _webViewController!.evaluateJavascript(
        source: JsBridge.getCourseContextScript,
      );
      if (result != null) {
        final contextStr = result is String ? result : result.toString();
        final context = jsonDecode(contextStr) as Map<String, dynamic>;
        setState(() {
          _currentSemester = context['semester']?.toString() ?? 'عام';
          _currentCourse = context['course']?.toString() ?? 'المقرر_العام';
          _currentWeek = context['week']?.toString() ?? 'ملفات';
        });
        debugPrint(
          'ZadBridge: Context → S:$_currentSemester C:$_currentCourse W:$_currentWeek',
        );
      }
    } catch (e) {
      debugPrint('ZadBridge: Error parsing context: $e');
    }
  }

  void _showDownloadsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DownloadsScreen(),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'الخروج من التطبيق',
            style: TextStyle(
              color: AppConstants.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'هل تريد الخروج من أكاديمية زاد؟',
            style: TextStyle(color: AppConstants.textLight),
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
                Navigator.of(context).maybePop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'خروج',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
