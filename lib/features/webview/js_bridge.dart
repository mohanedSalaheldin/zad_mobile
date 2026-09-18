/// JavaScript bridge scripts injected into the WebView to extract
/// course context (semester, course name, week) from page URL/title.
class JsBridge {
  /// Main injection script — runs on every page load.
  /// Sets up `window._ZadBridge` with context extraction methods.
  static const String contextExtractionScript = '''
    (function() {
      window._ZadBridge = {
        getCourseContext: function() {
          var url = window.location.href;
          var title = document.title || '';
          var result = {
            semester: '',
            course: '',
            week: '',
            pageTitle: title
          };

          // Try to extract semester from URL patterns
          // Example: /semester/1 or /level/2 or ?semester=3
          var semesterMatch = url.match(/[\\/?&](semester|level|مستوى)[\\/_=](\\d+)/i);
          if (semesterMatch) {
            result.semester = 'المستوى_' + semesterMatch[2];
          }

          // Try to extract course name from URL or breadcrumbs
          // Example: /course/tafseer or /subject/fiqh
          // But skip Moodle PHP pages like view.php, index.php
          var courseMatch = url.match(/[\\/?&](course|subject|مقرر|مادة)[\\/_=]([^\\/?&#]+)/i);
          if (courseMatch) {
            var courseVal = decodeURIComponent(courseMatch[2]).replace(/[\\-_+]/g, ' ');
            // Skip PHP file matches (e.g. view.php, index.php)
            if (!courseVal.match(/\\.php\$/i)) {
              result.course = courseVal;
            }
          }

          // Try to extract week from URL
          // Example: /week/3 or ?week=5
          var weekMatch = url.match(/[\\/?&](week|أسبوع|اسبوع)[\\/_=](\\d+)/i);
          if (weekMatch) {
            result.week = 'الأسبوع_' + weekMatch[2];
          }

          // Fallback: try to extract from page title
          if (!result.course && title) {
            // Try Moodle course title pattern: "المقرر: العقيدة"
            var moodleCourseMatch = title.match(/(?:المقرر|مقرر):\\s*(.+?)(?:\\s*[-|•]|\$)/);
            if (moodleCourseMatch) {
              result.course = moodleCourseMatch[1].trim();
            } else {
              // Remove common prefixes/suffixes
              var cleanTitle = title
                .replace(/أكاديمية زاد/g, '')
                .replace(/برنامج أكاديمية زاد/g, '')
                .replace(/\\|/g, '')
                .replace(/الصفحة الرئيسية/g, '')
                .replace(/الفصل (الأول|الثاني|الثالث|الرابع)/g, '')
                .trim();
              // Remove leading colon and spaces
              cleanTitle = cleanTitle.replace(/^[ :\\s]+/, '').trim();
              if (cleanTitle.length > 0 && cleanTitle.length < 80) {
                result.course = cleanTitle;
              }
            }
          }

          // Fallback: try to extract from breadcrumb elements
          if (!result.course) {
            var breadcrumbs = document.querySelectorAll('.breadcrumb-item, .breadcrumb a, nav[aria-label="breadcrumb"] a');
            if (breadcrumbs.length >= 2) {
              result.course = breadcrumbs[breadcrumbs.length - 1].textContent.trim();
            }
          }

          // Try h1/h2 headers for course name
          if (!result.course) {
            var header = document.querySelector('h1, h2.course-title, .course-name');
            if (header) {
              var text = header.textContent.trim();
              if (text.length > 0 && text.length < 80) {
                result.course = text;
              }
            }
          }

          // Defaults
          if (!result.semester) result.semester = 'عام';
          if (!result.course) result.course = 'المقرر_العام';
          if (!result.week) result.week = 'ملفات';

          return JSON.stringify(result);
        },

        getDownloadLinks: function() {
          var links = [];
          var anchors = document.querySelectorAll('a[href]');
          for (var i = 0; i < anchors.length; i++) {
            var href = anchors[i].href;
            var text = anchors[i].textContent.trim();
            if (href.match(/\\.(pdf|mp4|mp3|m4a|doc|docx|ppt|pptx|xls|xlsx|zip|rar|mkv|mov|avi|webm|wav|aac|ogg)(\$|\\?)/i)) {
              links.push({ url: href, title: text || href.split('/').pop() });
            }
          }
          return JSON.stringify(links);
        },

        isYouTubeUrl: function(url) {
          return /youtube\\.com\\/watch|youtu\\.be\\/|youtube\\.com\\/embed/.test(url);
        },

        extractYouTubeId: function(url) {
          var match = url.match(/(?:youtube\\.com\\/(?:watch\\?v=|embed\\/)|youtu\\.be\\/)([a-zA-Z0-9_-]{11})/);
          return match ? match[1] : null;
        }
      };

      // Notify Flutter that bridge is ready
      function notifyBridgeReady() {
        try {
          if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
            window.flutter_inappwebview.callHandler('onBridgeReady', true);
            return true;
          }
        } catch(e) {}
        return false;
      }

      if (!notifyBridgeReady()) {
        window.addEventListener('flutterInAppWebViewPlatformReady', function() {
          notifyBridgeReady();
        });
      }
    })();
  ''';

  /// Script to get current course context as JSON string
  static const String getCourseContextScript = '''
    (function() {
      if (window._ZadBridge) {
        return window._ZadBridge.getCourseContext();
      }
      return JSON.stringify({ semester: 'عام', course: 'المقرر_العام', week: 'ملفات', pageTitle: document.title });
    })();
  ''';

  /// Script to get all download links on the page
  static const String getDownloadLinksScript = '''
    (function() {
      if (window._ZadBridge) {
        return window._ZadBridge.getDownloadLinks();
      }
      return '[]';
    })();
  ''';

  /// Extract YouTube video ID from a URL
  static String? extractYouTubeVideoId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Check if URL is a YouTube link
  static bool isYouTubeUrl(String url) {
    return url.contains('youtube.com/watch') ||
        url.contains('youtu.be/') ||
        url.contains('youtube.com/embed');
  }

  /// Check if URL is a downloadable file
  static bool isDownloadableUrl(String url) {
    final extensions = [
      '.pdf', '.mp4', '.mp3', '.m4a', '.doc', '.docx',
      '.ppt', '.pptx', '.xls', '.xlsx', '.zip', '.rar',
      '.mkv', '.mov', '.avi', '.webm', '.wav', '.aac', '.ogg',
    ];
    final lowerUrl = url.toLowerCase().split('?').first;
    return extensions.any((ext) => lowerUrl.endsWith(ext));
  }
}
