import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:zad_mobile/app/constants.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const AudioPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setSource(DeviceFileSource(widget.filePath));

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        if (_isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _rotationController.stop();
        _rotationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        appBar: AppBar(
          backgroundColor: AppConstants.cardDark,
          foregroundColor: AppConstants.textLight,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rotating disc icon
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryColor.withValues(alpha: 0.3),
                          AppConstants.primaryDark.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      color: AppConstants.secondaryColor,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppConstants.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),

                // Progress slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppConstants.primaryLight,
                    inactiveTrackColor:
                        AppConstants.textMuted.withValues(alpha: 0.2),
                    thumbColor: AppConstants.secondaryColor,
                    overlayColor:
                        AppConstants.primaryLight.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(
                          0,
                          _duration.inSeconds.toDouble().clamp(1, double.infinity),
                        ),
                    max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),

                // Time labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speed control
                    TextButton(
                      onPressed: _toggleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppConstants.textMuted.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(
                            color: AppConstants.secondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Rewind 15s
                    IconButton(
                      onPressed: () {
                        _audioPlayer.seek(
                          _position - const Duration(seconds: 15),
                        );
                      },
                      icon: const Icon(
                        Icons.replay_10_rounded,
                        color: AppConstants.textLight,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play/Pause
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryLight,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Forward 15s
                    IconButton(
                      onPressed: () {
                        _audioPlayer.seek(
                          _position + const Duration(seconds: 15),
                        );
                      },
                      icon: const Icon(
                        Icons.forward_10_rounded,
                        color: AppConstants.textLight,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void _toggleSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    setState(() => _playbackSpeed = speeds[nextIndex]);
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
