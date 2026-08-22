import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses granular permissions
      final sdkInt = int.tryParse(
        await _getAndroidSdkVersion(),
      );

      if (sdkInt != null && sdkInt >= 33) {
        // Android 13+ doesn't need WRITE_EXTERNAL_STORAGE
        // App-specific directory access is automatic
        return true;
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
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
