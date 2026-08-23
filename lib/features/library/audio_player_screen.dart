import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_cubit.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_state.dart';

class AudioPlayerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const AudioPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AudioPlayerCubit()..init(filePath, autoPlay: true),
      child: _AudioPlayerView(title: title),
    );
  }
}

class _AudioPlayerView extends StatefulWidget {
  final String title;

  const _AudioPlayerView({required this.title});

  @override
  State<_AudioPlayerView> createState() => _AudioPlayerViewState();
}

class _AudioPlayerViewState extends State<_AudioPlayerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerCubit, AudioPlayerState>(
      listener: (context, state) {
        if (state.isPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          _rotationController.stop();
        }
        if (state.status == AudioPlayerStatus.completed) {
          _rotationController.reset();
        }
      },
      builder: (context, state) {
        final cubit = context.read<AudioPlayerCubit>();
        final durationMs = state.duration.inMilliseconds.toDouble();
        final hasValidDuration = durationMs > 0;
        final maxSliderValue = hasValidDuration ? durationMs : 1.0;
        final currentPosMs = state.displayPosition.inMilliseconds.toDouble();
        final sliderValue = hasValidDuration
            ? currentPosMs.clamp(0.0, maxSliderValue)
            : 0.0;

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
              child: SingleChildScrollView(
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
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.2),
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

                    // Progress slider wrapped with LTR Directionality for accurate touch mapping
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppConstants.primaryLight,
                          inactiveTrackColor:
                              AppConstants.textMuted.withValues(alpha: 0.2),
                          thumbColor: AppConstants.secondaryColor,
                          overlayColor:
                              AppConstants.primaryLight.withValues(alpha: 0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                            pressedElevation: 6,
                          ),
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: 0.0,
                          max: maxSliderValue,
                          onChangeStart: hasValidDuration
                              ? (val) {
                                  cubit.onDragStart(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                }
                              : null,
                          onChanged: hasValidDuration
                              ? (val) {
                                  cubit.onDragUpdate(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                }
                              : null,
                          onChangeEnd: hasValidDuration
                              ? (val) {
                                  cubit.onDragEnd(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),

                    // Time labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(state.displayPosition),
                            style: const TextStyle(
                              color: AppConstants.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(state.duration),
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
                          onPressed: () => cubit.cyclePlaybackSpeed(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppConstants.textMuted
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${state.playbackSpeed}x',
                              style: const TextStyle(
                                color: AppConstants.secondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Rewind 10s
                        IconButton(
                          onPressed: () =>
                              cubit.seekRelative(const Duration(seconds: -10)),
                          icon: const Icon(
                            Icons.replay_10_rounded,
                            color: AppConstants.textLight,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Play/Pause
                        GestureDetector(
                          onTap: () => cubit.togglePlay(),
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
                              state.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Forward 10s
                        IconButton(
                          onPressed: () =>
                              cubit.seekRelative(const Duration(seconds: 10)),
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
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '00:00';
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
