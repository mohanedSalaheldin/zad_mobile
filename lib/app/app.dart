import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_cubit.dart';

class ZadApp extends StatelessWidget {
  final Widget home;

  const ZadApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloadsCubit(),
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buildTheme(),
        home: home,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppConstants.primaryColor,
        onPrimary: Colors.white,
        secondary: AppConstants.secondaryColor,
        onSecondary: Colors.white,
        surface: AppConstants.cardDark,
        onSurface: AppConstants.textLight,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: AppConstants.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.cardDark,
        foregroundColor: AppConstants.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppConstants.textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.cardDark,
        contentTextStyle: const TextStyle(color: AppConstants.textLight),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppConstants.textLight,
      ),
    );
  }
}
