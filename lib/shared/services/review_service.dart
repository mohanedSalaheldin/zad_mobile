import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _keySuccessfulActions = 'successful_actions';
  static const String _keyHasReviewed = 'has_reviewed';

  /// يُستدعى بعد إتمام الطالب لمهمة ناجحة (مثل إكمال تنزيل درس أو فتح كتاب)
  /// تظهر نافذة التقييم المباشرة (In-App Review) من أسفل الشاشة داخل التطبيق حصراً بدون الخروج للمتجر.
  static Future<void> triggerInAppReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // حساب عدد المرات التي أكمل فيها المستخدم عملية تنزيل / دراسة
      int actionCount = (prefs.getInt(_keySuccessfulActions) ?? 0) + 1;
      await prefs.setInt(_keySuccessfulActions, actionCount);

      bool hasReviewed = prefs.getBool(_keyHasReviewed) ?? false;
      debugPrint('ReviewService: Action count = $actionCount, hasReviewed = $hasReviewed');

      // اطلب التقييم الداخلي فقط إذا قام بـ 3 عمليات ناجحة ولم يسبق له التقييم
      if (actionCount >= 3 && !hasReviewed) {
        if (await _inAppReview.isAvailable()) {
          // إظهار نافذة التقييم المباشرة الخاصة بـ Google Play داخل التطبيق
          await _inAppReview.requestReview();
          await prefs.setBool(_keyHasReviewed, true);
          debugPrint('ReviewService: requestReview called successfully inside the app.');
        } else {
          debugPrint('ReviewService: In-App Review is not available on this device.');
        }
      }
    } catch (e) {
      debugPrint('ReviewService error: $e');
    }
  }

  /// طلب نافذة التقييم الداخلي مباشرة (مثل الضغط على زر التقييم من الإعدادات)
  /// تبقى داخل التطبيق فقط ولا تفتح المتجر الخارجي إطلاقاً
  static Future<void> requestInAppReviewDirectly() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyHasReviewed, true);
        debugPrint('ReviewService: Direct In-App Review requested.');
      } else {
        debugPrint('ReviewService: In-App Review not available.');
      }
    } catch (e) {
      debugPrint('ReviewService direct request error: $e');
    }
  }

  /// إعادة تعيين العداد للتجربة
  static Future<void> resetReviewStateForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySuccessfulActions);
    await prefs.remove(_keyHasReviewed);
    debugPrint('ReviewService: Reset successful_actions and has_reviewed for testing.');
  }
}
