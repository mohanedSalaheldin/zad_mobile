import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
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
  String? _savedMoodleSession;
  late String _activeLmsHost;

  @override
  void initState() {
    super.initState();
    _activeLmsHost = StorageService.instance.getActiveLmsHost();
  }

  void _updateActiveLmsHost(WebUri? url) {
    final host = url?.host;
    if (host != null && host.contains('lms-') && host.endsWith('.zad-academy.com')) {
      if (_activeLmsHost != host) {
        _activeLmsHost = host;
        StorageService.instance.setActiveLmsHost(host);
        debugPrint('ZadBridge: Active LMS batch host updated to: $host');
      }
    }
  }

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

  /// Reloads the active LMS batch dashboard
  void loadHomeUrl() {
    final host = _activeLmsHost.isNotEmpty
        ? _activeLmsHost
        : StorageService.instance.getActiveLmsHost();
    _webViewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri('https://$host/'),
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
                  url: WebUri(
                    StorageService.instance.getActiveLmsHost().isNotEmpty
                        ? 'https://${StorageService.instance.getActiveLmsHost()}/'
                        : AppConstants.loginUrl,
                  ),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  useOnNavigationResponse: true,
                  sharedCookiesEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  allowsLinkPreview: false,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  userAgent: Platform.isIOS ? null : AppConstants.customUserAgent,
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
                  controller.addJavaScriptHandler(
                    handlerName: 'onLmsLoginSubmit',
                    callback: (args) {
                      debugPrint('ZadBridge: [JS] LMS Login Submit detected: $args');
                    },
                  );
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('ZadBridge [JS Console]: ${consoleMessage.messageLevel} | ${consoleMessage.message}');
                },
                onLoadStart: (controller, url) {
                  _updateActiveLmsHost(url);
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
                  _updateActiveLmsHost(url);
                  _updateLoginState(url);
                },
                onLoadStop: (controller, url) async {
                  _updateActiveLmsHost(url);
                  setState(() {
                    _isLoading = false;
                    _progress = 1.0;
                  });

                  if (Platform.isIOS) {
                    // Hook form submissions to track authentication POST
                    await controller.evaluateJavascript(source: '''
                      (function() {
                        if (window._zadHooked) return;
                        window._zadHooked = true;
                        const origSubmit = HTMLFormElement.prototype.submit;
                        HTMLFormElement.prototype.submit = function() {
                          try {
                            console.log('ZadBridge: Form submit called for: ' + (this.action || 'empty'));
                            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                              window.flutter_inappwebview.callHandler('onLmsLoginSubmit', { action: this.action });
                            }
                          } catch(e) {}
                          return origSubmit.apply(this, arguments);
                        };
                      })();
                    ''');

                    // Debug active cookies in WKHTTPCookieStore
                    try {
                      final cookies = await CookieManager.instance().getCookies(
                        url: url ?? WebUri('https://$_activeLmsHost'),
                      );
                      final cookieStr = cookies.map((c) => '${c.name}=${c.value}').join('; ');
                      debugPrint('ZadBridge [iOS Cookies @ ${url?.host}]: $cookieStr');
                    } catch (_) {}
                  }

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
                  _triggerDownload(url: url, fileName: fileName);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  _updateActiveLmsHost(navigationAction.request.url);

                  // Handle YouTube links — save as bookmark
                  if (JsBridge.isYouTubeUrl(url)) {
                    _triggerDownload(
                      url: url,
                      fileName: 'youtube_${JsBridge.extractYouTubeVideoId(url)}',
                      title: 'فيديو يوتيوب',
                    );
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Handle downloadable files
                  if (JsBridge.isDownloadableUrl(url)) {
                    final fileName = url.split('/').last.split('?').first;
                    _triggerDownload(url: url, fileName: fileName);
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onNavigationResponse: (controller, navigationResponse) async {
                  if (Platform.isIOS) {
                    final action = await _handleIosNavigationResponse(controller, navigationResponse);
                    if (action != null) {
                      return action;
                    }
                  }
                  return NavigationResponseAction.ALLOW;
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

  /// Intercepts navigation responses on iOS to solve the notorious WebKit 302/303 redirect
  /// cookie-drop bug during SSO authentication between zad-academy.com and lms-ar121.
  /// (Strictly guarded by Platform.isIOS to guarantee zero side effects on Android).
  Future<NavigationResponseAction?> _handleIosNavigationResponse(
    InAppWebViewController controller,
    NavigationResponse navigationResponse,
  ) async {
    try {
      final response = navigationResponse.response;
      if (response == null) return null;

      final statusCode = response.statusCode ?? 0;
      final urlStr = response.url?.toString() ?? '';
      final headers = response.headers ?? {};

      debugPrint('ZadBridge [iOS NavResponse]: status $statusCode from $urlStr');

      // 1. Extract Set-Cookie header (case-insensitive)
      String? rawSetCookie;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'set-cookie') {
          rawSetCookie = entry.value;
          break;
        }
      }

      // 2. Extract Location header (case-insensitive)
      String? locationHeader;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'location') {
          locationHeader = entry.value;
          break;
        }
      }

      if (rawSetCookie != null && rawSetCookie.isNotEmpty) {
        debugPrint('ZadBridge [iOS Set-Cookie]: $rawSetCookie');
        await _syncRawCookies(rawSetCookie);
      }

      // 3. Handle 301/302/303/307 Redirects
      if (statusCode >= 300 && statusCode < 400 && locationHeader != null && locationHeader.isNotEmpty) {
        debugPrint('ZadBridge [iOS Redirect]: $statusCode -> $locationHeader');

        // Resolve target URL
        Uri resolvedUri;
        try {
          resolvedUri = Uri.parse(locationHeader);
          if (!resolvedUri.hasScheme) {
            final base = response.url ?? WebUri('https://$_activeLmsHost');
            resolvedUri = base.uriValue.resolve(locationHeader);
          }
        } catch (_) {
          resolvedUri = Uri.parse('https://$_activeLmsHost');
        }

        final targetUrl = resolvedUri.toString();
        final isGoingToLogin = targetUrl.contains('/login') || targetUrl.contains('login.html');

        // If redirect is taking user to the main LMS dashboard/home (NOT to a login page)
        if (!isGoingToLogin) {
          // Check for MoodleSession from header or CookieManager
          String? sessionVal;
          if (rawSetCookie != null && rawSetCookie.contains('MoodleSession')) {
            final match = RegExp(r'MoodleSession=([^;]+)').firstMatch(rawSetCookie);
            sessionVal = match?.group(1);
          }

          if (sessionVal == null || sessionVal.isEmpty) {
            final cookies = await CookieManager.instance().getCookies(
              url: WebUri('https://$_activeLmsHost'),
            );
            final mCookie = cookies.where((c) => c.name == 'MoodleSession').firstOrNull;
            sessionVal = mCookie?.value ?? _savedMoodleSession;
          }

          if (sessionVal != null && sessionVal.isNotEmpty) {
            _savedMoodleSession = sessionVal;
            debugPrint('ZadBridge [iOS Session Found]: $sessionVal -> Loading target: $targetUrl');

            // Cancel the buggy WebKit redirect which drops cookies during 302/303
            // and reload manually with explicit Cookie header
            Future.microtask(() async {
              await Future.delayed(const Duration(milliseconds: 80));
              await controller.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(targetUrl),
                  headers: {
                    'Cookie': 'MoodleSession=$sessionVal',
                  },
                ),
              );
            });

            return NavigationResponseAction.CANCEL;
          }
        }
      }
    } catch (e) {
      debugPrint('ZadBridge [iOS NavResponse Note]: $e');
    }
    return null;
  }

  /// Synchronizes raw Set-Cookie strings across all necessary domains and stores with persistence.
  Future<void> _syncRawCookies(String rawSetCookie) async {
    try {
      final cookieManager = CookieManager.instance();
      final cookieDirectives = rawSetCookie.split(RegExp(r'\r?\n|, (?=[A-Za-z0-9_\-]+=[^;])'));

      for (final directive in cookieDirectives) {
        final parts = directive.split(';').map((s) => s.trim()).toList();
        if (parts.isEmpty || !parts[0].contains('=')) continue;

        final firstEq = parts[0].indexOf('=');
        final name = parts[0].substring(0, firstEq).trim();
        final value = parts[0].substring(firstEq + 1).trim();
        if (name.isEmpty) continue;

        if (name == 'MoodleSession') {
          _savedMoodleSession = value;
        }

        String? path;
        bool isSecure = false;
        bool isHttpOnly = false;

        for (int i = 1; i < parts.length; i++) {
          final partLower = parts[i].toLowerCase();
          if (partLower.startsWith('path=')) {
            path = parts[i].substring(5).trim();
          } else if (partLower == 'secure') {
            isSecure = true;
          } else if (partLower == 'httponly') {
            isHttpOnly = true;
          }
        }

        final expireTime = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;

        // 1. Host-only for active LMS batch host
        await cookieManager.setCookie(
          url: WebUri('https://$_activeLmsHost'),
          name: name,
          value: value,
          domain: _activeLmsHost,
          path: path ?? '/',
          isSecure: isSecure,
          isHttpOnly: isHttpOnly,
          expiresDate: expireTime,
        );

        if (_activeLmsHost != 'lms-ar121.zad-academy.com') {
          await cookieManager.setCookie(
            url: WebUri('https://lms-ar121.zad-academy.com'),
            name: name,
            value: value,
            domain: 'lms-ar121.zad-academy.com',
            path: path ?? '/',
            isSecure: isSecure,
            isHttpOnly: isHttpOnly,
            expiresDate: expireTime,
          );
        }

        // 2. Wildcard for .zad-academy.com (all subdomains)
        await cookieManager.setCookie(
          url: WebUri('https://$_activeLmsHost'),
          name: name,
          value: value,
          domain: '.zad-academy.com',
          path: path ?? '/',
          isSecure: isSecure,
          isHttpOnly: isHttpOnly,
          expiresDate: expireTime,
        );

        // 3. Main portal zad-academy.com
        await cookieManager.setCookie(
          url: WebUri('https://zad-academy.com'),
          name: name,
          value: value,
          domain: '.zad-academy.com',
          path: path ?? '/',
          isSecure: isSecure,
          isHttpOnly: isHttpOnly,
          expiresDate: expireTime,
        );
      }
    } catch (e) {
      debugPrint('ZadBridge: Cookie sync error: $e');
    }
  }

  /// Triggers a download and displays user feedback without blocking WebView execution
  void _triggerDownload({
    required String url,
    required String fileName,
    String? title,
  }) {
    debugPrint('ZadBridge: Triggering download: $url → $fileName');
    DownloadManager.instance.startDownload(
      url: url,
      fileName: fileName,
      semester: _currentSemester,
      course: _currentCourse,
      week: _currentWeek,
      title: title,
    );

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Clear any previous snackbars so they don't queue up or stick on screen
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.downloading_rounded,
              color: AppConstants.secondaryLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'جاري تحميل: $fileName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryDark,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 2200),
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: 'التنزيلات',
          textColor: AppConstants.secondaryLight,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            _switchToDownloadsTab(context);
          },
        ),
      ),
    );

    // Guaranteed auto-dismiss fallback timer (after 2.5 seconds)
    // Ensures the toast disappears on all devices even if OEM accessibility intercepts it
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
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
