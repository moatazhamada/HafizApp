import 'package:hafiz_app/core/utils/logger.dart';

class LocalWhisperService {
  Future<String?> transcribe({
    required String audioPath,
    String language = 'ar',
    dynamic model,
  }) async {
    Logger.warning('Local Whisper not available on web', feature: 'Whisper');
    return null;
  }
}
