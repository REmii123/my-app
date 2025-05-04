import 'package:flutter/material.dart';
import 'media_item.dart';
import 'audio_player_service.dart';

class SearchScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final AudioPlayerService audioPlayer;

  const SearchScreen({
    Key? key,
    required this.mediaItems,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late List<MediaItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.mediaItems;
  }

  Future<void> _playSong(int index) async {
    try {
      final paths = _filteredItems.map((item) => item.id).toList();
      await widget.audioPlayer.setPlaylist(paths, initialIndex: index);
      await widget.audioPlayer.play();
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
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search songs...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _filteredItems = widget.mediaItems
                  .where((item) => item.title.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          final color = item.extras?['color'] as Color? ?? Colors.purpleAccent;
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
            title: Text(
              item.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              item.artist ?? 'Unknown Artist',
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () => _playSong(index),
          );
        },
      ),
    );
  }
}