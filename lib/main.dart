import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:zad_mobile/app/app.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';
import 'package:zad_mobile/shared/services/permission_service.dart';
import 'package:zad_mobile/features/downloads/download_manager.dart';
import 'package:zad_mobile/features/webview/webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive mode — hide system bars for full-screen experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize services
  await StorageService.instance.init();
  await DownloadManager.instance.init();

  // Register download callback
  FlutterDownloader.registerCallback(DownloadManager.downloadCallback);

  // Request permissions
  await PermissionService.instance.requestAllPermissions();

  runApp(const ZadApp(home: WebViewScreen()));
}
