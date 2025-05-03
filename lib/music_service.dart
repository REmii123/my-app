import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class MusicService {
  static Future<List<Map<String, dynamic>>> getDeviceSongs() async {
    if (!await _checkPermissions()) return [];

    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return [];

      final musicDir = Directory(selectedDirectory);
      final files = await musicDir.list()
          .where((file) => file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))
          .toList();

      return files.map((file) => _createSongMap(file)).toList();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      return [];
    }
  }

  static Map<String, dynamic> _createSongMap(FileSystemEntity file) {
    final path = file.path;
    final fileName = path.split('/').last;
    return {
      'path': path,
      'title': fileName.replaceAll('.mp3', '').replaceAll('.m4a', ''),
      'artist': 'Unknown Artist',
      'color': _generateColor(fileName),
      'isAsset': false,
    };
  }

  static Future<bool> _checkPermissions() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      return (await Permission.storage.request()).isGranted;
    }
    return true;
  }

  static Color _generateColor(String input) {
    final colors = Colors.primaries;
    return colors[input.hashCode % colors.length];
  }
}