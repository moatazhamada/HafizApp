import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:hafiz_app/domain/entities/playback_state.dart';

/// Manages downloaded audio files and download queue
class LocalAudioManager {
  static const String _audioBoxName = 'download_queue';
  static const String _statusBoxName = 'download_status';
  static const String _playbackStateBoxName = 'audio_playback_state';

  Box<dynamic>? _audioBox;
  Box<dynamic>? _statusBox;
  Box<dynamic>? _playbackStateBox;

  bool _isInitialized = false;

  /// Initialize Hive boxes for audio management
  Future<void> initialize() async {
    if (_isInitialized) return;

    _audioBox = await Hive.openBox(_audioBoxName);
    _statusBox = await Hive.openBox(_statusBoxName);
    _playbackStateBox = await Hive.openBox(_playbackStateBoxName);
    _isInitialized = true;
  }

  /// Get application documents directory
  Future<String> get _applicationDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Get download directory for audio files
  Future<String> get downloadDirectory async {
    final baseDir = await _applicationDirectory;
    final dir = Directory('$baseDir/audio_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Download audio file from URL
  Future<Either<String, String>> downloadAudio({
    required String url,
    required String filename,
    required Function(int, int) onProgress,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final dir = await downloadDirectory;
      final filePath = '$dir/$filename';

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          final progress = (received / total * 100).toInt();
          onProgress(progress, total);
        },
      );

      return Right(filePath);
    } catch (e) {
      return Left('Failed to download audio: $e');
    }
  }

  /// Check if audio file exists locally
  Future<bool> fileExists(String filename) async {
    if (!_isInitialized) return false;
    final dir = await downloadDirectory;
    final filePath = '$dir/$filename';
    final file = File(filePath);
    return await file.exists();
  }

  /// Get local file path
  Future<String?> getLocalPath(String filename) async {
    if (!_isInitialized) return null;
    final dir = await downloadDirectory;
    final filePath = '$dir/$filename';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// Delete audio file from local storage
  Future<bool> deleteFile(String filename) async {
    try {
      final path = await getLocalPath(filename);
      if (path != null) {
        final file = File(path);
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get total downloaded size
  Future<int> getTotalDownloadedSize() async {
    if (!_isInitialized) return 0;

    final dir = await downloadDirectory;
    final files = Directory(dir).listSync();
    int totalSize = 0;
    for (final file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }

  /// Get download queue
  Future<List<Map<String, dynamic>>> getDownloadQueue() async {
    if (!_isInitialized) return [];

    final entries = _audioBox?.values.toList() ?? [];
    return entries.cast<Map<String, dynamic>>();
  }

  /// Add to download queue
  Future<void> addToQueue(Map<String, dynamic> downloadTask) async {
    if (!_isInitialized) await initialize();
    await _audioBox?.put(downloadTask['key'], downloadTask);
  }

  /// Remove from download queue
  Future<void> removeFromQueue(String key) async {
    if (!_isInitialized) return;
    await _audioBox?.delete(key);
  }

  /// Save playback state
  Future<void> savePlaybackState(PlaybackState state) async {
    if (!_isInitialized) await initialize();
    await _playbackStateBox?.put('current_state', {
      'surahNumber': state.currentSurahNumber,
      'verseNumber': state.currentVerseNumber,
      'positionMs': state.playbackPositionMs,
      'speed': state.playbackSpeed,
      'isPaused': state.isPaused,
      'isOffline': state.isOffline,
    });
  }

  /// Load playback state
  Future<PlaybackState?> loadPlaybackState() async {
    if (!_isInitialized) return null;

    final data = _playbackStateBox?.get('current_state') as Map?;
    if (data == null) return null;

    return PlaybackState(
      currentSurahNumber: data['surahNumber'] as int?,
      currentVerseNumber: data['verseNumber'] as int?,
      playbackPositionMs: (data['positionMs'] as num?)?.toDouble() ?? 0.0,
      playbackSpeed: (data['speed'] as num?)?.toDouble() ?? 1.0,
      isPaused: data['isPaused'] as bool? ?? true,
      isOffline: data['isOffline'] as bool? ?? false,
    );
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await _audioBox?.close();
    await _statusBox?.close();
    await _playbackStateBox?.close();
    _audioBox = null;
    _statusBox = null;
    _playbackStateBox = null;
    _isInitialized = false;
  }
}
