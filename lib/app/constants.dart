import 'package:flutter/material.dart';

class AppConstants {
  // App Identity
  static const String appTitle = 'رفيق زاد | منظم المقررات والتنزيلات';
  static const String appShortName = 'رفيق زاد';
  static const String appShortDescription =
      'أداة مساعدة غير رسمية لطلاب أكاديمية زاد لتنظيم المقررات وتنزيل الدروس أوفلاين.';

  // URLs
  static const String baseUrl = 'https://lms-ar121.zad-academy.com';
  static const String loginUrl = 'https://lms-ar121.zad-academy.com';
  static const String privacyPolicyUrl = 'https://zad-academy.com/privacy-policy';
  static const String faqUrl = 'https://zad-academy.com/loginqa';
  static const String forgotPasswordUrl = 'https://sap.zad.academy/login/forgot_password.php?lang=ar';
  static const String customUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 ZadMobile/1.0 Mobile Safari/537.36';

  // Hive Box Names
  static const String downloadsBoxName = 'zad_downloads_box';
  static const String settingsBoxName = 'zad_settings_box';

  // Palette - Zad Academy Inspired (Emerald Green, Gold, Midnight Navy, Off-white)
  static const Color primaryColor = Color(0xFF0F5B46); // Rich Islamic Emerald Green
  static const Color primaryDark = Color(0xFF09392C);
  static const Color primaryLight = Color(0xFF1B8A6B);
  static const Color secondaryColor = Color(0xFFC59B27); // Elegant Gold Accent
  static const Color secondaryLight = Color(0xFFE2BE5A);
  static const Color accentColor = Color(0xFF247BA0); // Soft Blue

  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  static const Color bgDark = Color(0xFF0D1512);
  static const Color cardDark = Color(0xFF16231E);
  static const Color textLight = Color(0xFFF1F5F9);

  // Storage defaults
  static const double defaultMaxStorageGb = 4.0;
}
