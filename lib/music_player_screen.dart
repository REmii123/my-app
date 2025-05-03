import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Map song;
  final List<Map> playlist;
  final int initialIndex;

  const MusicPlayerScreen({
    Key? key,
    required this.song,
    required this.playlist,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isShuffled = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _setupAudio();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favs.contains(widget.playlist[_currentIndex]['path']);
    });
  }

  Future<void> _setupAudio() async {
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });

    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    print('PLAYLIST LENGTH: ${widget.playlist.length}');
    if (widget.playlist.isEmpty) {
      print('ERROR: Playlist is empty!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist is empty. Cannot play.')),
      );
      return;
    }
    final song = widget.playlist[_currentIndex];
    print('Playing: ${song['path']}');
    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.file(song['path']),
          tag: MediaItem(
            id: song['path'],
            title: song['title'] ?? 'Unknown Title',
            artist: song['artist'] ?? 'Unknown Artist',
            album: song['album'] ?? 'Unknown Album',
            artUri: null,
          ),
        ),
      );
      await _audioPlayer.play();
      _loadFavorites();
    } catch (e) {
      print('Failed to play song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play this file.')),
      );
    }
  }

  void _playNext() {
    if (_isShuffled) {
      _playRandomSong();
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.playlist.length;
    });
    _playCurrentSong();
  }

  void _playPrevious() {
    if (_position.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length;
    });
    _playCurrentSong();
  }

  void _playRandomSong() {
    int newIndex = _currentIndex;
    while (newIndex == _currentIndex && widget.playlist.length > 1) {
      newIndex = DateTime.now().millisecondsSinceEpoch % widget.playlist.length;
    }
    setState(() {
      _currentIndex = newIndex;
    });
    _playCurrentSong();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    final path = widget.playlist[_currentIndex]['path'];
    setState(() {
      if (_isFavorite) {
        favs.remove(path);
        _isFavorite = false;
      } else {
        favs.add(path);
        _isFavorite = true;
      }
    });
    await prefs.setStringList('favorites', favs);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: song['color']?.withOpacity(0.8) ?? Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (song['color'] ?? Colors.grey).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.music_note, size: 120, color: Colors.white70),
              ),
            ),
            Column(
              children: [
                Text(
                  song['title'] ?? 'Unknown Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  song['artist'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0,
                  max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1,
                  activeColor: song['color'] ?? Colors.purpleAccent,
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70)),
                      Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isShuffled ? Icons.shuffle : Icons.shuffle_outlined,
                    color: _isShuffled ? Colors.purpleAccent : Colors.white70,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _isShuffled = !_isShuffled;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                  onPressed: _playPrevious,
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: song['color']?.withOpacity(0.2) ?? Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                  onPressed: _playNext,
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.purpleAccent : Colors.white70,
                    size: 28,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
