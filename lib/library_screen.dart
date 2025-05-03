import 'package:flutter/material.dart';
import 'music_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> songs;
  const LibraryScreen({Key? key, required this.songs}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _sortBy = 'artist';

  List<Map<String, dynamic>> get sortedSongs {
    final songs = List<Map<String, dynamic>>.from(widget.songs);
    songs.sort((a, b) => a[_sortBy].toString().compareTo(b[_sortBy].toString()));
    return songs;
  }

  void _openPlayer(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MusicPlayerScreen(
        song: widget.songs[index],
        playlist: widget.songs,
        initialIndex: index,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _sortBy = 'artist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sortBy == 'artist' ? Colors.grey[700] : Colors.grey[800],
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Sort by Artist'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _sortBy = 'title'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sortBy == 'title' ? Colors.grey[700] : Colors.grey[800],
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Sort by Title'),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.songs.isEmpty
              ? const Center(
            child: Text(
              'No songs available',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : ListView.builder(
            itemCount: sortedSongs.length,
            itemBuilder: (context, index) {
              final song = sortedSongs[index];
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
                  onTap: () => _openPlayer(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}