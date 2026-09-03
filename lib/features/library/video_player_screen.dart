import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/features/library/cubit/video_player_cubit.dart';
import 'package:zad_mobile/features/library/cubit/video_player_state.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String? filePath;
  final String? youtubeVideoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    this.filePath,
    this.youtubeVideoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    // Allow landscape and portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);

    if (widget.youtubeVideoId != null) {
      _initYouTube();
    }
  }

  void _initYouTube() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.youtubeVideoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.youtubeVideoId != null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
          ),
          body: Center(
            child: _buildYouTubePlayer(),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => VideoPlayerCubit()..init(widget.filePath!),
      child: _LocalVideoPlayerView(title: widget.title),
    );
  }

  Widget _buildYouTubePlayer() {
    if (_youtubeController == null) {
      return const CircularProgressIndicator(color: AppConstants.primaryLight);
    }
    return YoutubePlayer(
      controller: _youtubeController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppConstants.primaryLight,
      progressColors: const ProgressBarColors(
        playedColor: AppConstants.primaryLight,
        handleColor: AppConstants.secondaryColor,
      ),
    );
  }
}

class _LocalVideoPlayerView extends StatelessWidget {
  final String title;

  const _LocalVideoPlayerView({required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      builder: (context, state) {
        final cubit = context.read<VideoPlayerCubit>();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => cubit.toggleControls(),
              child: Center(
                child: !state.isInitialized || cubit.controller == null
                    ? const CircularProgressIndicator(
                        color: AppConstants.primaryLight,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video stream
                          Center(
                            child: AspectRatio(
                              aspectRatio: state.aspectRatio,
                              child: VideoPlayer(cubit.controller!),
                            ),
                          ),

                          // Top AppBar (when controls visible)
                          if (state.showControls)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => cubit.userInteracted(),
                                child: Container(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top + 8,
                                    left: 16,
                                    right: 16,
                                    bottom: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.85),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        onPressed: () =>
                                            Navigator.maybePop(context),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Bottom Controls overlay
                          if (state.showControls)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => cubit.userInteracted(),
                                child: _buildControlsOverlay(context, state, cubit),
                              ),
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

  Widget _buildControlsOverlay(
    BuildContext context,
    VideoPlayerState state,
    VideoPlayerCubit cubit,
  ) {
    final durationMs = max(1.0, state.duration.inMilliseconds.toDouble());
    final positionMs = state.displayPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, durationMs);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubbing Slider inside LTR Directionality for precise coordinates
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppConstants.primaryLight,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppConstants.secondaryColor,
                overlayColor: AppConstants.primaryLight.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                  pressedElevation: 6,
                ),
              ),
              child: Slider(
                value: positionMs,
                min: 0.0,
                max: durationMs,
                onChangeStart: (val) {
                  cubit.onDragStart(
                    Duration(milliseconds: val.toInt()),
                  );
                },
                onChanged: (val) {
                  cubit.onDragUpdate(
                    Duration(milliseconds: val.toInt()),
                  );
                },
                onChangeEnd: (val) {
                  cubit.onDragEnd(
                    Duration(milliseconds: val.toInt()),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Action Buttons and Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Elapsed time
              Text(
                _formatDuration(state.displayPosition),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Rewind 10s
              IconButton(
                icon: const Icon(
                  Icons.replay_10_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () =>
                    cubit.seekRelative(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 8),
              // Play/Pause
              IconButton(
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () => cubit.togglePlay(),
              ),
              const SizedBox(width: 8),
              // Forward 10s
              IconButton(
                icon: const Icon(
                  Icons.forward_10_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () =>
                    cubit.seekRelative(const Duration(seconds: 10)),
              ),
              const Spacer(),
              // Total duration
              Text(
                _formatDuration(state.duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
