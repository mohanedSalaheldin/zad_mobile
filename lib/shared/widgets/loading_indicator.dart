import 'package:flutter/material.dart';
import 'package:zad_mobile/app/constants.dart';

class ZadLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final double progress;

  const ZadLoadingIndicator({
    super.key,
    required this.isLoading,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value > 0 ? value : null,
            minHeight: 3,
            backgroundColor: AppConstants.primaryDark.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.secondaryColor,
            ),
          );
        },
      ),
    );
  }
}
