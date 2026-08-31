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

  // ─── Palette — Zad Academy Light Mode (Gold / Warm Brown) ───
  static const Color primaryColor   = Color(0xFF8B5E3C); // Rich warm brown
  static const Color primaryDark    = Color(0xFF5C3A1E); // Deep dark brown
  static const Color primaryLight   = Color(0xFFB07D4E); // Medium warm brown
  static const Color secondaryColor = Color(0xFFC59B27); // Elegant gold
  static const Color secondaryLight = Color(0xFFE2BE5A); // Light gold
  static const Color accentColor    = Color(0xFFD4A843); // Bright gold accent

  // Light Mode surfaces
  static const Color bgLight       = Color(0xFFFAF6EF); // Creamy off-white
  static const Color cardLight     = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceVariant= Color(0xFFF5ECD9); // Warm beige surface
  static const Color textDark      = Color(0xFF2D1B0E); // Very dark brown text
  static const Color textMuted     = Color(0xFF8B7355); // Muted warm brown
  static const Color dividerColor  = Color(0xFFE8D5B5); // Warm beige divider

  // Backwards-compat aliases (used across the app)
  static const Color bgDark   = bgLight;
  static const Color cardDark = cardLight;
  static const Color textLight = textDark;

  // Storage defaults
  static const double defaultMaxStorageGb = 4.0;
}
