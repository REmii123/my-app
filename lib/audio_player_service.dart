import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerService {
  final AudioPlayer player;
  List<String>? _playlist;
  int _currentIndex = 0;

  AudioPlayerService() : player = AudioPlayer() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> dispose() async {
    await player.dispose();
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> setPlaylist(List<String> paths, {int initialIndex = 0}) async {
    _playlist = paths;
    _currentIndex = initialIndex;
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: paths.map((path) => AudioSource.uri(Uri.file(path))).toList(),
      ),
      initialIndex: initialIndex,
    );
  }

  Future<void> skipToNext() async {
    if (_playlist == null || _playlist!.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist!.length;
    await player.seek(Duration.zero, index: _currentIndex);
  }

  Future<void> skipToPrevious() async {
    if (_playlist == null || _playlist!.isEmpty) return;
    final position = await player.position;
    if (position.inSeconds > 3) {
      await player.seek(Duration.zero);
      return;
    }
    _currentIndex = (_currentIndex - 1 + _playlist!.length) % _playlist!.length;
    await player.seek(Duration.zero, index: _currentIndex);
  }

  Future<void> skipToIndex(int index) async {
    if (_playlist == null || index < 0 || index >= _playlist!.length) return;
    _currentIndex = index;
    await player.seek(Duration.zero, index: index);
  }

  Stream<Duration> get positionStream => player.positionStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<double?> get volumeStream => player.volumeStream;
}