import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  /// التحقق من وجود تحديث جديد في متجر Google Play
  static Future<AppUpdateInfo?> checkForUpdate({
    bool triggerUpdate = true,
  }) async {
    // In-App Updates خاصة بنظام Android ومتجر Google Play فقط
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      debugPrint('UpdateService: updateAvailability = ${info.updateAvailability}');

      if (info.updateAvailability == UpdateAvailability.updateAvailable && triggerUpdate) {
        if (info.immediateUpdateAllowed) {
          // تحديث فوري مباشر
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // تحديث مرن في الخلفية ثم استكماله
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
      return info;
    } catch (e) {
      // في بيئة التطوير (Debug) أو التحميل الجانبي (Sideload)، لا يتوفر متجر Google Play
      debugPrint('UpdateService check error: $e');
      return null;
    }
  }
}
