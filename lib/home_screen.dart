import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'audio_player_service.dart';
import 'media_item.dart';
import 'library_screen.dart';
import 'music_player_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final AudioPlayerService audioPlayer;

  const HomeScreen({super.key, required this.audioPlayer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MediaItem> _mediaItems = [];
  List<MediaItem> _recentlyPlayed = [];
  List<MediaItem> _recentlyAdded = [];
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadSongs();
    _prepareLists();
    _startAutoSlide();
  }

  Future<void> _requestPermissions() async {
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> foundSongs = [];

    final directories = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Music',
      '/sdcard/Download',
      '/sdcard/Music',
    ];

    final seenPaths = <String>{};

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          final files = await dir.list(recursive: true).toList();
          for (final file in files) {
            if (file is File &&
                (file.path.endsWith('.mp3') ||
                    file.path.endsWith('.m4a') ||
                    file.path.endsWith('.aac'))) {
              final path = file.path;
              if (seenPaths.contains(path)) continue;
              seenPaths.add(path);

              final fileName = p.basenameWithoutExtension(file.path);
              foundSongs.add({
                'title': fileName,
                'artist': 'Unknown Artist',
                'path': path,
                'color': _getColor(foundSongs.length),
                'lastModified': await file.lastModified(),
              });
            }
          }
        } catch (e) {
          debugPrint('Error loading songs: $e');
        }
      }
    }

    _mediaItems = foundSongs.map((song) => MediaItem(
      id: song['path'],
      title: song['title'],
      artist: song['artist'],
      artUri: Uri.parse('asset:///assets/music_note.png'),
      extras: {'color': song['color'], 'lastModified': song['lastModified']},
    )).toList();

    setState(() => _isLoading = false);
  }

  void _prepareLists() {
    if (_mediaItems.isEmpty) return;

    _recentlyPlayed = _mediaItems.length > 3
        ? _mediaItems.sublist(0, 3)
        : List.from(_mediaItems);

    _recentlyAdded = List.from(_mediaItems)
      ..sort((a, b) => (b.extras!['lastModified'] as DateTime)
          .compareTo(a.extras!['lastModified'] as DateTime));
    if (_recentlyAdded.length > 5) {
      _recentlyAdded = _recentlyAdded.sublist(0, 5);
    }
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF6A8D92),
      Color(0xFF7D5A5A),
      Color(0xFF8F6F56),
      Color(0xFF6E7582),
      Color(0xFF7E7F9A),
      Color(0xFF9A8F7E),
    ];
    return colors[index % colors.length];
  }

  void _startAutoSlide() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _recentlyPlayed.isNotEmpty) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _recentlyPlayed.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _playSong(int index) async {
    try {
      final paths = _mediaItems.map((item) => item.id).toList();
      await widget.audioPlayer.setPlaylist(paths, initialIndex: index);
      await widget.audioPlayer.play();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MusicPlayerScreen(
            playlist: _mediaItems,
            initialIndex: index,
            audioPlayer: widget.audioPlayer,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('RhythMix'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    mediaItems: _mediaItems,
                    audioPlayer: widget.audioPlayer,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecentlyPlayed(),
            _buildRecentlyAdded(),
            _buildAllSongs(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    if (_recentlyPlayed.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recently Played',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _recentlyPlayed.length,
              itemBuilder: (context, index) {
                final song = _recentlyPlayed[index];
                final color = song.extras!['color'] as Color;
                return GestureDetector(
                  onTap: () => _playSong(_mediaItems.indexOf(song)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, Colors.black87],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.album, color: Colors.white, size: 28),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _playSong(_mediaItems.indexOf(song)),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 60,
                            left: 16,
                            right: 16,
                            child: Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            bottom: 36,
                            left: 16,
                            right: 16,
                            child: Text(
                              song.artist ?? 'Unknown Artist',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAdded() {
    if (_recentlyAdded.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recently Added',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentlyAdded.length,
            itemBuilder: (context, index) {
              final song = _recentlyAdded[index];
              final color = song.extras!['color'] as Color;
              return GestureDetector(
                onTap: () => _playSong(_mediaItems.indexOf(song)),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 40,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _playSong(_mediaItems.indexOf(song)),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist ?? 'Unknown Artist',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllSongs() {
    if (_mediaItems.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Songs',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LibraryScreen(
                        mediaItems: _mediaItems,
                        audioPlayer: widget.audioPlayer,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mediaItems.length > 5 ? 5 : _mediaItems.length,
          itemBuilder: (context, index) {
            final song = _mediaItems[index];
            final color = song.extras!['color'] as Color;
            return GestureDetector(
              onTap: () => _playSong(index),
              child: Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist ?? 'Unknown Artist',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: GestureDetector(
                    onTap: () => _playSong(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.purpleAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}