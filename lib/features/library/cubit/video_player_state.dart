class VideoPlayerState {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final Duration dragPosition;
  final bool isDragging;
  final bool isPlaying;
  final bool isInitialized;
  final bool showControls;
  final double aspectRatio;
  final String? errorMessage;

  const VideoPlayerState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.dragPosition = Duration.zero,
    this.isDragging = false,
    this.isPlaying = false,
    this.isInitialized = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.errorMessage,
  });

  Duration get displayPosition => isDragging ? dragPosition : position;

  VideoPlayerState copyWith({
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    Duration? dragPosition,
    bool? isDragging,
    bool? isPlaying,
    bool? isInitialized,
    bool? showControls,
    double? aspectRatio,
    String? errorMessage,
  }) {
    return VideoPlayerState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      dragPosition: dragPosition ?? this.dragPosition,
      isDragging: isDragging ?? this.isDragging,
      isPlaying: isPlaying ?? this.isPlaying,
      isInitialized: isInitialized ?? this.isInitialized,
      showControls: showControls ?? this.showControls,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      errorMessage: errorMessage,
    );
  }
}
