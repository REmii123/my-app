import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';
import 'media_item.dart';

class MusicPlayerScreen extends StatefulWidget {
  final List<MediaItem> playlist;
  final int initialIndex;
  final AudioPlayerService audioPlayer;

  const MusicPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
    required this.audioPlayer,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late int _currentIndex;
  bool _isFavorite = false;
  bool _isShuffled = false;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favs.contains(widget.playlist[_currentIndex].id);
    });
  }

  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    String songId = widget.playlist[_currentIndex].id;

    if (favs.contains(songId)) {
      favs.remove(songId);
    } else {
      favs.add(songId);
    }

    await prefs.setStringList('favorites', favs);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[_currentIndex];
    final color = song.extras?['color'] as Color? ?? Colors.purpleAccent;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<PlayerState>(
        stream: widget.audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final isPlaying = playerState?.playing ?? false;
          final position = widget.audioPlayer.player.position;
          final duration = widget.audioPlayer.player.duration ?? Duration.zero;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Album Art
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.music_note,
                            size: 100,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.white70,
                              size: 30,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Song Info
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.artist ?? 'Unknown Artist',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        StreamBuilder<Duration>(
                          stream: widget.audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            return Slider(
                              min: 0,
                              max: duration.inSeconds.toDouble(),
                              value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
                              onChanged: (value) {
                                widget.audioPlayer.player.seek(Duration(seconds: value.toInt()));
                              },
                              activeColor: color,
                              inactiveColor: Colors.grey[700],
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StreamBuilder<Duration>(
                                stream: widget.audioPlayer.positionStream,
                                builder: (context, snapshot) {
                                  final position = snapshot.data ?? Duration.zero;
                                  return Text(
                                    _formatDuration(position),
                                    style: const TextStyle(color: Colors.white70),
                                  );
                                },
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: _isShuffled ? color : Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _isShuffled = !_isShuffled;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
                        onPressed: () => widget.audioPlayer.skipToPrevious(),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 42,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              widget.audioPlayer.pause();
                            } else {
                              widget.audioPlayer.play();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
                        onPressed: () => widget.audioPlayer.skipToNext(),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: _isRepeating ? color : Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _isRepeating = !_isRepeating;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}