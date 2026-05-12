import flutter_sound

// Flutter's GeneratedPluginRegistrant expects FlutterSoundPlugin, but the
// flutter_sound macOS implementation uses TaudioPlugin. This typealias bridges
// the naming mismatch so plugin registration succeeds.
public typealias FlutterSoundPlugin = TaudioPlugin
