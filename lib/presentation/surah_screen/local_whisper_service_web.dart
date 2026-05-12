import 'package:flutter/foundation.dart';

class LocalWhisperService {
  Future<String?> transcribe({
    required String audioPath,
    String language = 'ar',
    dynamic model,
  }) async {
    debugPrint('Local Whisper not available on web');
    return null;
  }
}
