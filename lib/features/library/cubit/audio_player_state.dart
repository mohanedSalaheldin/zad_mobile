enum AudioPlayerStatus {
  initial,
  loading,
  ready,
  completed,
  error,
}

class AudioPlayerState {
  final Duration position;
  final Duration duration;
  final Duration dragPosition;
  final bool isDragging;
  final bool isPlaying;
  final double playbackSpeed;
  final AudioPlayerStatus status;
  final String? errorMessage;

  const AudioPlayerState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.dragPosition = Duration.zero,
    this.isDragging = false,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.status = AudioPlayerStatus.initial,
    this.errorMessage,
  });

  Duration get displayPosition => isDragging ? dragPosition : position;

  AudioPlayerState copyWith({
    Duration? position,
    Duration? duration,
    Duration? dragPosition,
    bool? isDragging,
    bool? isPlaying,
    double? playbackSpeed,
    AudioPlayerStatus? status,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      dragPosition: dragPosition ?? this.dragPosition,
      isDragging: isDragging ?? this.isDragging,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
