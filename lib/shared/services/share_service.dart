import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const String appShareMessage =
      'تطبيق رفيق زاد | نزّل محاضرات ومقررات أكاديمية زاد وتابع دراستك بدون إنترنت! حمل التطبيق من هنا: https://rafeeqzad.vercel.app/';

  /// مشاركة التطبيق مع رسالة دعوة ورابط التنزيل
  static Future<void> shareApp({Rect? sharePositionOrigin}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: appShareMessage,
          subject: 'تطبيق رفيق زاد للطلاب',
          title: 'مشاركة تطبيق رفيق زاد',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      debugPrint('ShareService error: $e');
    }
  }
}
