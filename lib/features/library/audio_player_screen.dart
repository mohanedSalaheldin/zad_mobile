import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_cubit.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_state.dart';
import 'package:zad_mobile/shared/services/audio_handler.dart';

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
      duration: const Duration(seconds: 12),
    );
    if (ZadAudioHandler.instance.isPlayingNotifier.value) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    // NOTE: We do NOT call cubit.stop() here.
    // The Cubit.close() does NOT stop playback → audio continues in background.
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
            backgroundColor: AppConstants.bgLight,
            appBar: AppBar(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                widget.title,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              actions: [
                // Background playback indicator
                if (state.isPlaying)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Tooltip(
                      message: 'الصوت يعمل في الخلفية',
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rotating disc
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppConstants.primaryColor,
                                AppConstants.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.headphones_rounded,
                            color: Colors.white,
                            size: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppConstants.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Background hint
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppConstants.dividerColor),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headset_rounded,
                              size: 14,
                              color: AppConstants.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'يمكنك الاستماع للمحاضرة في الخلفية',
                              style: TextStyle(
                                color: AppConstants.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Progress slider
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppConstants.primaryColor,
                            inactiveTrackColor: AppConstants.dividerColor,
                            thumbColor: AppConstants.secondaryColor,
                            overlayColor: AppConstants.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
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
                      const SizedBox(height: 32),

                      // Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Speed
                          GestureDetector(
                            onTap: () => cubit.cyclePlaybackSpeed(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppConstants.dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: AppConstants.surfaceVariant,
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
                          const SizedBox(width: 20),
                          // Rewind 10s
                          IconButton(
                            onPressed: () => cubit.seekRelative(
                              const Duration(seconds: -10),
                            ),
                            icon: Icon(
                              Icons.replay_10_rounded,
                              color: AppConstants.primaryColor,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Play/Pause button
                          GestureDetector(
                            onTap: () => cubit.togglePlay(),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppConstants.primaryColor,
                                    AppConstants.primaryDark,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Forward 10s
                          IconButton(
                            onPressed: () =>
                                cubit.seekRelative(const Duration(seconds: 10)),
                            icon: Icon(
                              Icons.forward_10_rounded,
                              color: AppConstants.primaryColor,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stop button (ends background playback)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await cubit.stop();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('إيقاف وإغلاق'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
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
