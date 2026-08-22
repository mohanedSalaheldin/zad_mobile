import 'package:flutter/material.dart';
import 'package:zad_mobile/app/constants.dart';

class FloatingLibraryButton extends StatefulWidget {
  final VoidCallback onTap;
  final int activeDownloads;

  const FloatingLibraryButton({
    super.key,
    required this.onTap,
    this.activeDownloads = 0,
  });

  @override
  State<FloatingLibraryButton> createState() => _FloatingLibraryButtonState();
}

class _FloatingLibraryButtonState extends State<FloatingLibraryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.activeDownloads > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingLibraryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeDownloads > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.activeDownloads > 0 ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 28,
            ),
            if (widget.activeDownloads > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${widget.activeDownloads}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
