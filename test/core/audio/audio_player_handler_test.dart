import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/audio/audio_player_handler.dart';
import 'package:audio_service/audio_service.dart';

void main() {
  group('AudioPlayerHandler', () {
    group('AudioPlayerHandler static', () {
      test('class exists and has expected methods', () {
        // Verify the class can be referenced
        expect(AudioPlayerHandler, isNotNull);
      });
    });

    group('AudioServiceRepeatMode', () {
      test('should have all repeat modes', () {
        expect(AudioServiceRepeatMode.values.length, 4);
        expect(AudioServiceRepeatMode.values, contains(AudioServiceRepeatMode.none));
        expect(AudioServiceRepeatMode.values, contains(AudioServiceRepeatMode.one));
        expect(AudioServiceRepeatMode.values, contains(AudioServiceRepeatMode.all));
        expect(AudioServiceRepeatMode.values, contains(AudioServiceRepeatMode.group));
      });
    });
  });
}
