import 'package:flutter/foundation.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class LocalWhisperService {
  final WhisperController _controller = WhisperController();

  Future<String?> transcribe({
    required String audioPath,
    String language = 'ar',
    WhisperModel model = WhisperModel.base,
  }) async {
    try {
      await _controller.downloadModel(model);
      final result = await _controller.transcribe(
        model: model,
        audioPath: audioPath,
        lang: language,
        withTimestamps: false,
        convert: false,
      );
      return result?.transcription.text.trim();
    } catch (e) {
      debugPrint('Local Whisper failed: $e');
      return null;
    }
  }
}
