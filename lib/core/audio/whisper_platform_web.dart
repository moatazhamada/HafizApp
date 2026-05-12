enum WhisperModel { tiny, base, small }

Future<String> getWhisperModelDir() async => '';

Uri getWhisperModelUri(WhisperModel model) => Uri.parse('');

String getWhisperModelName(WhisperModel model) => model.name;
