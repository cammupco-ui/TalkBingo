import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audioplayers/audioplayers.dart'; // Keep import for signature compat

/// Dedicated just_audio player for voice messages.
/// ExoPlayer (Android) handles WebM/Opus natively — unlike MediaPlayer.
ja.AudioPlayer? _voicePlayer;

/// Native: Use just_audio (ExoPlayer) for reliable WebM/Opus playback.
/// The `player` parameter is kept for API compatibility but not used —
/// we use just_audio's AudioPlayer instead of audioplayers'.
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  try {
    // Dispose previous player to avoid state issues
    await _voicePlayer?.dispose();
    _voicePlayer = ja.AudioPlayer();

    debugPrint('[AudioHelper] Playing via just_audio: $url');
    await _voicePlayer!.setUrl(url);
    await _voicePlayer!.play();
    debugPrint('[AudioHelper] just_audio playback started');
  } catch (e) {
    debugPrint('[AudioHelper] just_audio playback error: $e');
    rethrow;
  }
}

void stopWebAudio() {
  _voicePlayer?.stop();
}
