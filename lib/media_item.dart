class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Uri artUri;
  final Map<String, dynamic> extras;

  MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.artUri,
    required this.extras,
  });
}