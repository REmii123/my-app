import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

import 'library_screen.dart';
import 'music_player_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _recentlyPlayed = [];
  List<Map<String, dynamic>> _recentlyAdded = [];
  bool _isLoading = true;
  int _currentSongIndex = 0;
  bool _isPlaying = false;
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
    _audioPlayer.dispose();
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
                'album': 'Unknown Album',
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

    setState(() {
      _songs = foundSongs;
      _isLoading = false;
    });
  }

  void _prepareLists() {
    if (_songs.isEmpty) return;

    _recentlyPlayed = _songs.length > 3 ? _songs.sublist(0, 3) : List.from(_songs);

    final sorted = List<Map<String, dynamic>>.from(_songs)
      ..sort((a, b) => b['lastModified'].compareTo(a['lastModified']));
    _recentlyAdded = sorted.length > 5 ? sorted.sublist(0, 5) : sorted;
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
      _currentSongIndex = index;
      await _audioPlayer.setFilePath(_songs[index]['path']);
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: ${e.toString()}')),
      );
    }
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
                return GestureDetector(
                  onTap: () => _playSong(_songs.indexWhere((s) => s['path'] == song['path'])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [song['color'], Colors.black87],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: song['color'].withOpacity(0.5),
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
                            top: 16,
                            right: 16,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            left: 16,
                            right: 16,
                            child: Text(
                              song['title'],
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
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Text(
                              song['artist'],
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
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentlyAdded.length,
            itemBuilder: (context, index) {
              final song = _recentlyAdded[index];
              return GestureDetector(
                onTap: () => _playSong(_songs.indexWhere((s) => s['path'] == song['path'])),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: song['color'].withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          song['title'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song['artist'],
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildAllSongs() {
    if (_songs.isEmpty) return const SizedBox();

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
                      builder: (context) => LibraryScreen(songs: _songs),
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
          itemCount: _songs.length > 5 ? 5 : _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: song['color'].withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: Text(
                    song['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song['artist'],
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
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
            onPressed: () {},
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
}