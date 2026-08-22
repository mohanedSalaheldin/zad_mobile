import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zad_mobile/app/constants.dart';

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
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Lock to landscape for video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);

    if (widget.youtubeVideoId != null) {
      _initYouTube();
    } else if (widget.filePath != null) {
      _initLocalVideo();
    }
  }

  void _initLocalVideo() {
    _videoController = VideoPlayerController.file(File(widget.filePath!))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _videoController!.play();
      }).catchError((e) {
        debugPrint('VideoPlayer error: $e');
      });

    _videoController!.addListener(() {
      if (mounted) setState(() {});
    });
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
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _showControls
            ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
              )
            : null,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Center(
            child: !_isInitialized
                ? const CircularProgressIndicator(
                    color: AppConstants.primaryLight,
                  )
                : widget.youtubeVideoId != null
                    ? _buildYouTubePlayer()
                    : _buildLocalPlayer(),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator(
        color: AppConstants.primaryLight,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        if (_showControls)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppConstants.primaryLight,
                      bufferedColor: AppConstants.textMuted,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Time elapsed
                      Text(
                        _formatDuration(_videoController!.value.position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Rewind 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          final pos = _videoController!.value.position;
                          _videoController!.seekTo(
                            pos - const Duration(seconds: 10),
                          );
                        },
                      ),
                      // Play/Pause
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        },
                      ),
                      // Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          final pos = _videoController!.value.position;
                          _videoController!.seekTo(
                            pos + const Duration(seconds: 10),
                          );
                        },
                      ),
                      const Spacer(),
                      // Duration
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYouTubePlayer() {
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
