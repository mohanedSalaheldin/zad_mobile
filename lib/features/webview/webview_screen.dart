import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/widgets/loading_indicator.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/webview/js_bridge.dart';

class WebViewScreen extends StatefulWidget {
  final ValueChanged<bool>? onLoginStateChanged;
  final VoidCallback? onOpenDownloads;

  const WebViewScreen({
    super.key,
    this.onLoginStateChanged,
    this.onOpenDownloads,
  });

  @override
  State<WebViewScreen> createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  String _currentSemester = 'عام';
  String _currentCourse = 'المقرر_العام';
  String _currentWeek = 'ملفات';
  bool _isLoginPage = false;

  bool _checkIsLoginUrl(WebUri? url) {
    if (url == null) return false;
    return url.toString().toLowerCase().contains('login');
  }

  void _updateLoginState(WebUri? url) {
    final isLogin = _checkIsLoginUrl(url);
    if (_isLoginPage != isLogin) {
      setState(() => _isLoginPage = isLogin);
      widget.onLoginStateChanged?.call(isLogin);
    }
  }

  /// Reloads the initial login/home URL
  void loadHomeUrl() {
    _webViewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(AppConstants.loginUrl),
      ),
    );
  }

  Future<bool> canGoBack() async {
    return (_webViewController != null && await _webViewController!.canGoBack());
  }

  Future<void> goBack() async {
    await _webViewController?.goBack();
  }

  void showExitDialog() {
    _showExitDialog();
  }

  // Keep page alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: AppConstants.bgLight,
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
                  controller.addJavaScriptHandler(
                    handlerName: 'onBridgeReady',
                    callback: (args) {
                      debugPrint('ZadBridge: JS bridge ready');
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  final isLogin = _checkIsLoginUrl(url);
                  if (_isLoginPage != isLogin) {
                    setState(() => _isLoginPage = isLogin);
                    widget.onLoginStateChanged?.call(isLogin);
                  }
                  setState(() {
                    _isLoading = true;
                    _progress = 0;
                  });
                },
                onUpdateVisitedHistory: (controller, url, isReload) {
                  _updateLoginState(url);
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                    _progress = 1.0;
                  });
                  await controller.evaluateJavascript(
                    source: JsBridge.contextExtractionScript,
                  );
                  await _updateCourseContext();
                  _updateLoginState(url);
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
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppConstants.primaryDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'التنزيلات',
                        textColor: AppConstants.secondaryLight,
                        onPressed: () {
                          // Switch to downloads tab via the parent navigator
                          _switchToDownloadsTab(context);
                        },
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

              // Quick access button to offline downloads on login screen
              if (_isLoginPage)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _switchToDownloadsTab(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_for_offline_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'التنزيلات (أوفلاين)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
  }

  /// Switches the parent MainNavigationScreen to Downloads tab (index 1)
  void _switchToDownloadsTab(BuildContext context) {
    if (widget.onOpenDownloads != null) {
      widget.onOpenDownloads!();
      return;
    }
    // Walk up to find the BottomNavigationBar scaffold and switch tab
    final scaffold = context.findAncestorStateOfType<
        // ignore: invalid_use_of_protected_member
        State>();
    if (scaffold != null && scaffold.mounted) {
      try {
        // Access MainNavigationScreen's setState via a named method if possible
        (scaffold as dynamic).switchToDownloads();
      } catch (_) {}
    }
  }

  Future<void> _updateCourseContext() async {
    if (_webViewController == null) return;
    try {
      final result = await _webViewController!.evaluateJavascript(
        source: JsBridge.getCourseContextScript,
      );
      if (result != null) {
        final contextStr = result is String ? result : result.toString();
        final ctx = jsonDecode(contextStr) as Map<String, dynamic>;
        setState(() {
          _currentSemester = ctx['semester']?.toString() ?? 'عام';
          _currentCourse = ctx['course']?.toString() ?? 'المقرر_العام';
          _currentWeek = ctx['week']?.toString() ?? 'ملفات';
        });
        debugPrint(
          'ZadBridge: Context → S:$_currentSemester C:$_currentCourse W:$_currentWeek',
        );
      }
    } catch (e) {
      debugPrint('ZadBridge: Error parsing context: $e');
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'الخروج من التطبيق',
            style: TextStyle(
              color: AppConstants.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'هل تريد الخروج من أكاديمية زاد؟',
            style: TextStyle(color: AppConstants.textDark),
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
                SystemNavigator.pop();
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
