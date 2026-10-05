import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  /// Storage permission is only needed on Android 12 and below.
  /// On Android 13+, the app uses app-specific directories (no permission needed)
  /// and system pickers for any media selection (no permission needed).
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = int.tryParse(
        await _getAndroidSdkVersion(),
      );

      if (sdkInt != null && sdkInt >= 33) {
        // Android 13+: app-specific directory access is automatic,
        // and we use system pickers — no storage permission needed.
        return true;
      }

      // Android 12 and below: request legacy storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> requestAllPermissions() async {
    await requestStoragePermission();
    await requestNotificationPermission();
  }

  Future<String> _getAndroidSdkVersion() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return result.stdout.toString().trim();
    } catch (_) {
      return '30'; // fallback
    }
  }
}
