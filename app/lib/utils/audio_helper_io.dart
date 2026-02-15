import 'package:audioplayers/audioplayers.dart';

/// Native: Use audioplayers package directly
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  if (player != null) {
    await player.stop();
    await player.play(UrlSource(url));
  } else {
    final p = AudioPlayer();
    await p.play(UrlSource(url));
  }
}

void stopWebAudio() {
  // No-op on native
}
