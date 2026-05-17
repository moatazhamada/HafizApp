import 'package:hafiz_app/core/utils/logger.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class LocalWhisperService {
  final WhisperController _controller = WhisperController();
  bool _modelDownloaded = false;
  bool _isDisposed = false;

  Future<String?> transcribe({
    required String audioPath,
    String language = 'ar',
    WhisperModel model = WhisperModel.base,
  }) async {
    if (_isDisposed) return null;
    try {
      if (!_modelDownloaded) {
        await _controller.downloadModel(model);
        _modelDownloaded = true;
      }
      final result = await _controller.transcribe(
        model: model,
        audioPath: audioPath,
        lang: language,
        withTimestamps: false,
        convert: false,
      );
      return result?.transcription.text.trim();
    } catch (e) {
      Logger.warning('Local Whisper failed: $e', feature: 'Whisper');
      return null;
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _modelDownloaded = false;
  }
}
