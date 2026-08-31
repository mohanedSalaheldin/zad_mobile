import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_cubit.dart';
import 'package:zad_mobile/features/downloads/cubit/downloads_state.dart';
import 'package:zad_mobile/features/downloads/downloads_screen.dart';
import 'package:zad_mobile/features/webview/webview_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<WebViewScreenState> _webViewKey =
      GlobalKey<WebViewScreenState>();

  late final List<Widget> _pages = [
    WebViewScreen(key: _webViewKey),
    const DownloadsPage(),
  ];

  void switchToDownloads() {
    setState(() => _currentIndex = 1);
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      // Whenever Home is clicked (whether switching to it or already on it),
      // reload the initial Home URL
      _webViewKey.currentState?.loadHomeUrl();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return BlocBuilder<DownloadsCubit, DownloadsState>(
      builder: (context, state) {
        final activeCount = state.activeDownloads.length;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                elevation: 0,
                backgroundColor: Colors.white,
                selectedItemColor: AppConstants.primaryColor,
                unselectedItemColor: AppConstants.textMuted,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'الرئيسية',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildDownloadsIcon(activeCount, false),
                    activeIcon: _buildDownloadsIcon(activeCount, true),
                    label: 'التنزيلات',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadsIcon(int activeCount, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected
              ? Icons.download_rounded
              : Icons.download_outlined,
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textMuted,
        ),
        if (activeCount > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppConstants.secondaryColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
