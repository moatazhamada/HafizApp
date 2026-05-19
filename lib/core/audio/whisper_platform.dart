import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

export 'package:whisper_ggml_plus/whisper_ggml_plus.dart' show WhisperModel;

Future<String> getWhisperModelDir() => WhisperController.getModelDir();

Uri getWhisperModelUri(WhisperModel model) => model.modelUri;

String getWhisperModelName(WhisperModel model) => model.modelName;
