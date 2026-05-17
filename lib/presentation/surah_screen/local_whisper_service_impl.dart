import 'package:hafiz_app/core/utils/logger.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

enum WhisperError { noAudio, modelError, permission }

class WhisperResult {
  final String? text;
  final WhisperError? error;
  const WhisperResult._({this.text, this.error});
  factory WhisperResult.success(String text) = _WhisperSuccess;
  factory WhisperResult.failure(WhisperError error) = _WhisperFailure;
  bool get isSuccess => text != null;
}

class _WhisperSuccess extends WhisperResult {
  _WhisperSuccess(String text) : super._(text: text);
}

class _WhisperFailure extends WhisperResult {
  _WhisperFailure(WhisperError error) : super._(error: error);
}

class LocalWhisperService {
  final WhisperController _controller = WhisperController();
  bool _modelDownloaded = false;
  bool _isDisposed = false;

  Future<WhisperResult> transcribe({
    required String audioPath,
    String language = 'ar',
    WhisperModel model = WhisperModel.base,
  }) async {
    if (_isDisposed) return WhisperResult.failure(WhisperError.modelError);
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
      final text = result?.transcription.text.trim();
      if (text == null || text.isEmpty) {
        return WhisperResult.failure(WhisperError.noAudio);
      }
      return WhisperResult.success(text);
    } on Exception catch (e) {
      Logger.warning('Local Whisper failed: $e', feature: 'Whisper');
      if (e.toString().contains('Permission')) {
        return WhisperResult.failure(WhisperError.permission);
      }
      return WhisperResult.failure(WhisperError.modelError);
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _modelDownloaded = false;
  }
}
