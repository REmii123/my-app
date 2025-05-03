import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final List<MediaItem> _playlist = [];

  MyAudioHandler() {
    _loadPlaylist();
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        playing: _player.playing,
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: AudioServiceRepeatMode.none,
        shuffleMode: AudioServiceShuffleMode.none,
        updatePosition: _player.position,
        // Remove updateTime
      ));
    });
  }

  Future<void> _loadPlaylist() async {
    // Example: Load a simple playlist
    _playlist.add(const MediaItem(
      id: '1',
      album: 'Test Album',
      title: 'Test Song 1',
    ));

    // Set the initial playlist in the audio player
    try {
      await _player.setAudioSource(ConcatenatingAudioSource(
          children: _playlist
              .map((item) => AudioSource.uri(Uri.parse(item.id)))
              .toList()));
    } catch (e) {
      print("Error loading playlist: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seek(Duration.zero, index: _player.currentIndex! + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seek(Duration.zero, index: _player.currentIndex! - 1);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.close();
    await queue.close();
    await mediaItem.close();
  }
}
