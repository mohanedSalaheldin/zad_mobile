import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_mobile/features/library/cubit/audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  AudioPlayerCubit() : super(const AudioPlayerState());

  Future<void> init(String filePath, {bool autoPlay = true}) async {
    emit(state.copyWith(status: AudioPlayerStatus.loading));
    try {
      await _player.setSource(DeviceFileSource(filePath));

      // Attempt to immediately get duration if already parsed
      final initialDuration = await _player.getDuration();
      if (initialDuration != null && initialDuration > Duration.zero) {
        emit(state.copyWith(
          duration: initialDuration,
          status: AudioPlayerStatus.ready,
        ));
      }

      _durationSubscription = _player.onDurationChanged.listen((d) {
        if (!isClosed && d > Duration.zero) {
          emit(state.copyWith(
            duration: d,
            status: AudioPlayerStatus.ready,
          ));
        }
      });

      _positionSubscription = _player.onPositionChanged.listen((p) async {
        if (!isClosed && !state.isDragging) {
          // If duration is still zero or exceeded, query duration again
          if (state.duration == Duration.zero || p > state.duration) {
            final d = await _player.getDuration();
            if (d != null && d > Duration.zero) {
              emit(state.copyWith(position: p, duration: d));
              return;
            }
          }
          emit(state.copyWith(position: p));
        }
      });

      _playerStateSubscription = _player.onPlayerStateChanged.listen((s) {
        if (!isClosed) {
          emit(state.copyWith(isPlaying: s == PlayerState.playing));
        }
      });

      _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
        if (!isClosed) {
          emit(state.copyWith(
            isPlaying: false,
            position: Duration.zero,
            status: AudioPlayerStatus.completed,
          ));
        }
      });

      if (autoPlay) {
        await _player.resume();
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

  void onDragStart(Duration pos) {
    emit(state.copyWith(isDragging: true, dragPosition: pos));
  }

  void onDragUpdate(Duration pos) {
    emit(state.copyWith(dragPosition: pos));
  }

  Future<void> onDragEnd(Duration targetPos) async {
    final maxMs = state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 0;
    final clamped = Duration(
      milliseconds: targetPos.inMilliseconds.clamp(0, maxMs),
    );
    emit(state.copyWith(position: clamped, dragPosition: clamped, isDragging: false));
    await _player.seek(clamped);
  }

  Future<void> seekRelative(Duration delta) async {
    final maxMs = state.duration.inMilliseconds > 0 ? state.duration.inMilliseconds : 0;
    final newPosMs = (state.position.inMilliseconds + delta.inMilliseconds).clamp(0, maxMs);
    final target = Duration(milliseconds: newPosMs);
    emit(state.copyWith(position: target, dragPosition: target));
    await _player.seek(target);
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _player.pause();
    } else {
      if (state.status == AudioPlayerStatus.completed ||
          (state.duration > Duration.zero && state.position >= state.duration)) {
        await _player.seek(Duration.zero);
      }
      await _player.resume();
    }
  }

  Future<void> cyclePlaybackSpeed() async {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(state.playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    final nextSpeed = speeds[nextIndex];
    await _player.setPlaybackRate(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  @override
  Future<void> close() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}
