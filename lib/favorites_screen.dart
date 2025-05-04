import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'music_player_screen.dart';
import 'media_item.dart';
import 'audio_player_service.dart';

class FavoritesScreen extends StatefulWidget {
  final List<MediaItem> allSongs;
  final AudioPlayerService audioPlayer;

  const FavoritesScreen({
    Key? key,
    required this.allSongs,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoritePaths = [];
  List<MediaItem> _favoriteSongs = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favPaths = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favoritePaths = favPaths;
      _favoriteSongs = widget.allSongs
          .where((song) => _favoritePaths.contains(song.id))
          .toList();
    });
  }

  Future<void> _toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoritePaths.contains(path)) {
        _favoritePaths.remove(path);
      } else {
        _favoritePaths.add(path);
      }
      _favoriteSongs = widget.allSongs
          .where((song) => _favoritePaths.contains(song.id))
          .toList();
    });
    await prefs.setStringList('favorites', _favoritePaths);
  }

  void _openPlayer(int index) {
    final song = _favoriteSongs[index];
    final originalIndex = widget.allSongs.indexWhere((s) => s.id == song.id);

    if (originalIndex != -1) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MusicPlayerScreen(
          playlist: widget.allSongs,
          initialIndex: originalIndex,
          audioPlayer: widget.audioPlayer,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              'Your Favorites',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          if (_favoriteSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.purpleAccent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the heart icon to add songs to favorites',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final song = _favoriteSongs[index];
                    final color = song.extras?['color'] as Color? ?? Colors.purpleAccent;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _openPlayer(index),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.7),
                                Colors.grey[900]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist ?? 'Unknown Artist',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.purpleAccent,
                                    size: 28,
                                  ),
                                  onPressed: () => _toggleFavorite(song.id),
                                ),
                                const SizedBox(width: 8),
                                Container(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _favoriteSongs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}