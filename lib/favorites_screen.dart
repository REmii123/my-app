import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allSongs;
  const FavoritesScreen({Key? key, required this.allSongs}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoritePaths = [];
  List<Map<String, dynamic>> _favoriteSongs = [];

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
          .where((song) => _favoritePaths.contains(song['path']))
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
          .where((song) => _favoritePaths.contains(song['path']))
          .toList();
    });
    await prefs.setStringList('favorites', _favoritePaths);
  }

  void _openPlayer(int index) {
    final song = _favoriteSongs[index];
    final originalIndex = widget.allSongs.indexWhere((s) => s['path'] == song['path']);

    if (originalIndex != -1) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MusicPlayerScreen(
          song: song,
          playlist: widget.allSongs,
          initialIndex: originalIndex,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_favoriteSongs.isEmpty) {
      return const Center(
        child: Text(
          'No favorites added yet.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      itemCount: _favoriteSongs.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[800]),
      itemBuilder: (context, index) {
        final song = _favoriteSongs[index];
        final isFav = _favoritePaths.contains(song['path']);
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: song['color']?.withOpacity(0.3) ?? Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(
            song['title'] ?? 'Unknown Title',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            song['artist'] ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.purpleAccent : Colors.white70,
            ),
            onPressed: () => _toggleFavorite(song['path']),
          ),
          onTap: () => _openPlayer(index),
        );
      },
    );
  }
}