import 'dart:async';
import 'dart:ui' show Color;
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton wrapper around AudioService + AudioPlayer.
/// Provides background playback with notification media controls
/// (Play / Pause / Seek / Stop).
class ZadAudioHandler extends BaseAudioHandler with SeekHandler {
  // ─── Singleton ───────────────────────────────────────────────
  static ZadAudioHandler? _instance;
  static ZadAudioHandler get instance {
    assert(_instance != null,
        'ZadAudioHandler.init() must be called before accessing instance');
    return _instance!;
  }

  /// Call once in main() before runApp.
  static Future<void> init() async {
    if (_instance != null) return;
    _instance = await AudioService.init(
      builder: () => ZadAudioHandler._(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.zad.mobile.audio',
        androidNotificationChannelName: 'زاد — تشغيل الصوت',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: const Color(0xFF8B5E3C), // primaryColor
      ),
    );
  }

  // ─── Internal player ─────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  // Public notifiers so the Cubit can observe state
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isCompletedNotifier = ValueNotifier(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1.0);

  ZadAudioHandler._() {
    // Bind AudioPlayer events → AudioService playbackState
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      isPlayingNotifier.value = state == PlayerState.playing;
      _broadcastState();
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      if (d > Duration.zero) {
        durationNotifier.value = d;
        _updateMediaItem();
      }
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      positionNotifier.value = p;
      _broadcastState();
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      isPlayingNotifier.value = false;
      isCompletedNotifier.value = true;
      positionNotifier.value = Duration.zero;
      _broadcastState();
    });
  }

  String? _currentFilePath;
  String? get currentFilePath => _currentFilePath;

  // ─── Public API ──────────────────────────────────────────────

  /// Load a new file and start playing.
  Future<void> openFile({
    required String filePath,
    required String title,
    bool autoPlay = true,
  }) async {
    // If it's already the same file loaded and initialized
    if (_currentFilePath == filePath && durationNotifier.value > Duration.zero) {
      if (autoPlay && !isPlayingNotifier.value) {
        await play();
      }
      return;
    }

    _currentFilePath = filePath;
    isCompletedNotifier.value = false;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;

    // Set MediaItem so the notification shows proper metadata
    mediaItem.add(MediaItem(
      id: filePath,
      title: title,
      album: 'أكاديمية زاد',
      artUri: null,
    ));

    await _player.stop();
    await _player.setSource(DeviceFileSource(filePath));

    // Fetch initial duration
    final d = await _player.getDuration();
    if (d != null && d > Duration.zero) {
      durationNotifier.value = d;
      _updateMediaItem();
    }

    if (autoPlay) await _player.resume();
  }

  // ─── BaseAudioHandler overrides ──────────────────────────────

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _currentFilePath = null;
    isPlayingNotifier.value = false;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final maxMs = durationNotifier.value.inMilliseconds;
    final clamped = Duration(
      milliseconds: position.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0),
    );
    positionNotifier.value = clamped;
    await _player.seek(clamped);
  }

  // ─── Playback speed ──────────────────────────────────────────

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setPlaybackRate(speed);
    speedNotifier.value = speed;
    _broadcastState();
  }

  // ─── Relative seek ───────────────────────────────────────────

  Future<void> seekRelative(Duration delta) async {
    final current = positionNotifier.value;
    final target = current + delta;
    await seek(target);
  }

  // ─── Internal helpers ────────────────────────────────────────

  void _updateMediaItem() {
    final current = mediaItem.value;
    if (current != null) {
      mediaItem.add(current.copyWith(duration: durationNotifier.value));
    }
  }

  void _broadcastState() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        if (isPlayingNotifier.value) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: isPlayingNotifier.value,
      updatePosition: positionNotifier.value,
      bufferedPosition: durationNotifier.value,
      speed: speedNotifier.value,
    ));
  }

  // ─── Cleanup ─────────────────────────────────────────────────

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _disposePlayer();
  }

  Future<void> _disposePlayer() async {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    await _player.dispose();
  }
}
