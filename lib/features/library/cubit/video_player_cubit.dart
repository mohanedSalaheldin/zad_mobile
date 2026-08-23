import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:zad_mobile/features/library/cubit/video_player_state.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  VideoPlayerController? _controller;
  Timer? _autoHideTimer;

  VideoPlayerCubit() : super(const VideoPlayerState());

  VideoPlayerController? get controller => _controller;

  Future<void> init(String filePath) async {
    try {
      _controller = VideoPlayerController.file(File(filePath));
      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      await _controller!.play();
      emit(state.copyWith(
        isInitialized: true,
        duration: _controller!.value.duration,
        aspectRatio: _controller!.value.aspectRatio,
        isPlaying: _controller!.value.isPlaying,
        showControls: true,
      ));
      _startAutoHideTimer();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _videoListener() {
    if (_controller == null || isClosed) return;
    final value = _controller!.value;

    Duration maxBuffered = Duration.zero;
    if (value.buffered.isNotEmpty) {
      maxBuffered = value.buffered.last.end;
    }

    if (!state.isDragging) {
      emit(state.copyWith(
        position: value.position,
        duration: value.duration,
        bufferedPosition: maxBuffered,
        isPlaying: value.isPlaying,
      ));
    }
  }

  void onDragStart(Duration pos) {
    _cancelAutoHideTimer();
    emit(state.copyWith(isDragging: true, dragPosition: pos));
  }

  void onDragUpdate(Duration pos) {
    emit(state.copyWith(dragPosition: pos));
  }

  Future<void> onDragEnd(Duration targetPos) async {
    if (_controller == null) return;
    final maxMs =
        state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 0;
    final clamped = Duration(
      milliseconds: targetPos.inMilliseconds.clamp(0, maxMs),
    );
    emit(state.copyWith(position: clamped, dragPosition: clamped));
    await _controller!.seekTo(clamped);
    emit(state.copyWith(isDragging: false));
    _startAutoHideTimer();
  }

  Future<void> seekRelative(Duration delta) async {
    if (_controller == null) return;
    final maxMs =
        state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 0;
    final newPosMs =
        (state.position.inMilliseconds + delta.inMilliseconds).clamp(0, maxMs);
    final target = Duration(milliseconds: newPosMs);
    emit(state.copyWith(position: target));
    await _controller!.seekTo(target);
    _startAutoHideTimer();
  }

  Future<void> togglePlay() async {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      await _controller!.pause();
      _cancelAutoHideTimer();
    } else {
      await _controller!.play();
      _startAutoHideTimer();
    }
  }

  void toggleControls() {
    final next = !state.showControls;
    emit(state.copyWith(showControls: next));
    if (next) {
      _startAutoHideTimer();
    } else {
      _cancelAutoHideTimer();
    }
  }

  void userInteracted() {
    if (state.showControls) {
      _startAutoHideTimer();
    }
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (state.isPlaying) {
      _autoHideTimer = Timer(const Duration(seconds: 4), () {
        if (!isClosed) {
          emit(state.copyWith(showControls: false));
        }
      });
    }
  }

  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelAutoHideTimer();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    return super.close();
  }
}
