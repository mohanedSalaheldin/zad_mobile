import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_state.dart';
import 'package:zad_mobile/shared/services/audio_handler.dart';

/// Cubit that drives the AudioPlayerScreen UI.
/// Delegates actual playback to [ZadAudioHandler] which runs as a
/// background Foreground Service and exposes notification controls.
class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final ZadAudioHandler _handler = ZadAudioHandler.instance;

  // ValueNotifier listeners
  VoidCallback? _playingListener;
  VoidCallback? _positionListener;
  VoidCallback? _durationListener;
  VoidCallback? _completedListener;
  VoidCallback? _speedListener;

  AudioPlayerCubit() : super(const AudioPlayerState());

  Future<void> init(String filePath, {bool autoPlay = true}) async {
    // 1. Immediately sync with handler's current state
    final isSameFile = _handler.currentFilePath == filePath;
    final currentDuration =
        isSameFile ? _handler.durationNotifier.value : Duration.zero;
    final currentPosition =
        isSameFile ? _handler.positionNotifier.value : Duration.zero;
    final isCurrentlyPlaying = isSameFile && _handler.isPlayingNotifier.value;

    emit(state.copyWith(
      isPlaying: isCurrentlyPlaying,
      position: currentPosition,
      duration: currentDuration,
      playbackSpeed: _handler.speedNotifier.value,
      status: currentDuration > Duration.zero
          ? AudioPlayerStatus.ready
          : AudioPlayerStatus.loading,
    ));

    try {
      // 2. Subscribe to handler notifications
      _playingListener = () {
        if (!isClosed) {
          emit(state.copyWith(
            isPlaying: _handler.isPlayingNotifier.value,
          ));
        }
      };
      _positionListener = () {
        if (!isClosed && !state.isDragging) {
          emit(state.copyWith(position: _handler.positionNotifier.value));
        }
      };
      _durationListener = () {
        if (!isClosed) {
          emit(state.copyWith(
            duration: _handler.durationNotifier.value,
            status: AudioPlayerStatus.ready,
          ));
        }
      };
      _completedListener = () {
        if (!isClosed && _handler.isCompletedNotifier.value) {
          emit(state.copyWith(
            isPlaying: false,
            position: Duration.zero,
            status: AudioPlayerStatus.completed,
          ));
        }
      };
      _speedListener = () {
        if (!isClosed) {
          emit(state.copyWith(playbackSpeed: _handler.speedNotifier.value));
        }
      };

      _handler.isPlayingNotifier.addListener(_playingListener!);
      _handler.positionNotifier.addListener(_positionListener!);
      _handler.durationNotifier.addListener(_durationListener!);
      _handler.isCompletedNotifier.addListener(_completedListener!);
      _handler.speedNotifier.addListener(_speedListener!);

      // 3. Open the file in the handler
      final title = filePath.split('/').last;
      await _handler.openFile(
        filePath: filePath,
        title: title,
        autoPlay: autoPlay,
      );

      if (!isClosed) {
        emit(state.copyWith(
          isPlaying: _handler.isPlayingNotifier.value,
          position: _handler.positionNotifier.value,
          duration: _handler.durationNotifier.value,
          status: AudioPlayerStatus.ready,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: AudioPlayerStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  // ─── Drag / seek ─────────────────────────────────────────────

  void onDragStart(Duration pos) {
    emit(state.copyWith(isDragging: true, dragPosition: pos));
  }

  void onDragUpdate(Duration pos) {
    emit(state.copyWith(dragPosition: pos));
  }

  Future<void> onDragEnd(Duration targetPos) async {
    emit(state.copyWith(
      position: targetPos,
      dragPosition: targetPos,
      isDragging: false,
    ));
    await _handler.seek(targetPos);
  }

  Future<void> seekRelative(Duration delta) async {
    final target = state.position + delta;
    emit(state.copyWith(position: target, dragPosition: target));
    await _handler.seekRelative(delta);
  }

  // ─── Playback controls ───────────────────────────────────────

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _handler.pause();
    } else {
      if (state.status == AudioPlayerStatus.completed ||
          (state.duration > Duration.zero &&
              state.position >= state.duration)) {
        await _handler.seek(Duration.zero);
      }
      await _handler.play();
    }
  }

  /// Stops audio completely (ends background foreground service too).
  Future<void> stop() async {
    await _handler.stop();
    if (!isClosed) {
      emit(state.copyWith(
        isPlaying: false,
        position: Duration.zero,
        status: AudioPlayerStatus.completed,
      ));
    }
  }

  Future<void> cyclePlaybackSpeed() async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(state.playbackSpeed);
    final nextSpeed = speeds[(currentIndex + 1) % speeds.length];
    await _handler.setSpeed(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  // ─── Cleanup ─────────────────────────────────────────────────

  @override
  Future<void> close() {
    if (_playingListener != null) {
      _handler.isPlayingNotifier.removeListener(_playingListener!);
    }
    if (_positionListener != null) {
      _handler.positionNotifier.removeListener(_positionListener!);
    }
    if (_durationListener != null) {
      _handler.durationNotifier.removeListener(_durationListener!);
    }
    if (_completedListener != null) {
      _handler.isCompletedNotifier.removeListener(_completedListener!);
    }
    if (_speedListener != null) {
      _handler.speedNotifier.removeListener(_speedListener!);
    }
    // NOTE: We do NOT stop playback here — background audio keeps running
    // even after the screen is closed.
    return super.close();
  }
}

// Helper typedef to avoid importing dart:ui in the cubit
typedef VoidCallback = void Function();
