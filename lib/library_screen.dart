import 'package:flutter/material.dart';
import 'media_item.dart';
import 'audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final AudioPlayerService audioPlayer;

  const LibraryScreen({
    Key? key,
    required this.mediaItems,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}


class _LibraryScreenState extends State<LibraryScreen> {
  String _sortBy = 'title';
  String _currentFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  List<MediaItem> get sortedMediaItems {
    List<MediaItem> items = List.from(widget.mediaItems);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      items = items.where((item) =>
      item.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (item.artist?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply type filter
    if (_currentFilter != 'all') {
      items = items.where((item) =>
          item.id.toString().endsWith('.$_currentFilter')
      ).toList();
    }

    // Apply sorting
    if (_sortBy == 'title') {
      items.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortBy == 'artist') {
      items.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
    } else if (_sortBy == 'album') {
      items.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
    }

    return items;
  }

  Future<void> _playSong(int index) async {
    try {
      await widget.audioPlayer.setPlaylist(
        sortedMediaItems.map((item) => item.id).toList(),
        initialIndex: index,
      );
      await widget.audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Library'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[900],
                        hintText: 'Search songs...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          _buildFilterChip('MP3', 'mp3'),
                          _buildFilterChip('M4A', 'm4a'),
                          _buildFilterChip('AAC', 'aac'),
                          _buildSortChip('Title', 'title'),
                          _buildSortChip('Artist', 'artist'),
                          _buildSortChip('Album', 'album'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (sortedMediaItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 60,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs found',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final song = sortedMediaItems[index];
                    final color = song.extras?['color'] as Color? ?? Colors.purpleAccent;
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
                        song.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song.artist ?? 'Unknown Artist',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => _playSong(index),
                    );
                  },
                  childCount: sortedMediaItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _currentFilter == value,
        onSelected: (selected) {
          setState(() {
            _currentFilter = selected ? value : 'all';
          });
        },
        selectedColor: Colors.purpleAccent,
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(
          color: _currentFilter == value ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _sortBy == value,
        onSelected: (selected) {
          setState(() {
            _sortBy = value;
          });
        },
        selectedColor: Colors.purpleAccent,
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(
          color: _sortBy == value ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}