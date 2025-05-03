import 'package:flutter/material.dart';
import 'music_player_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> songs;

  const SearchScreen({Key? key, required this.songs}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      setState(() {
        _searchResults = widget.songs.where((song) {
          final title = song['title'].toString().toLowerCase();
          final artist = song['artist'].toString().toLowerCase();
          return title.contains(query) || artist.contains(query);
        }).toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search songs...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ),
      body: _searchResults.isNotEmpty
          ? ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final song = _searchResults[index];
          return Card(
            color: Colors.grey[850],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: song['color'].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white, size: 20),
              ),
              title: Text(
                song['title'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                song['artist'],
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              onTap: () {
                final index = widget.songs.indexWhere((s) => s['path'] == song['path']);
                if (index != -1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MusicPlayerScreen(song: song, playlist: widget.songs, initialIndex: index),
                    ),
                  );
                }
              },
            ),
          );
        },
      )
          : Center(
        child: Text(
          'No songs found.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
