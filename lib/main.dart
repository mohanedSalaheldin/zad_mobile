import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:zad_mobile/app/app.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/shared/services/permission_service.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/navigation/main_navigation_screen.dart';
import 'package:zad_mobile/shared/services/audio_handler.dart';
import 'package:zad_mobile/shared/services/notification_service.dart';
import 'package:zad_mobile/shared/services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Light mode — transparent status bar with dark icons
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize services
  await StorageService.instance.init();
  await DownloadManager.instance.init();
  await NotificationService.instance.init();

  // Initialize background audio handler
  await ZadAudioHandler.init();

  // Register download callback
  FlutterDownloader.registerCallback(DownloadManager.downloadCallback);

  // Request permissions
  await PermissionService.instance.requestAllPermissions();

  // Non-blocking in-app update check on startup
  UpdateService.checkForUpdate();

  runApp(const ZadApp(home: MainNavigationScreen()));
}
