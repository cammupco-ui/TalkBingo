import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';

html.AudioElement? _webAudioElement;

/// Web: Use HTML5 Audio element with retry logic for AbortError
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  // Stop any existing playback first
  stopWebAudio();
  
  // Small delay to let browser release previous audio resources
  await Future.delayed(const Duration(milliseconds: 100));

  _webAudioElement = html.AudioElement(url);
  
  // Try without crossOrigin first (more compatible with Supabase)
  try {
    await _webAudioElement!.play();
  } catch (e) {
    // If AbortError, wait and retry
    await Future.delayed(const Duration(milliseconds: 200));
    stopWebAudio();
    _webAudioElement = html.AudioElement(url);
    _webAudioElement!.crossOrigin = 'anonymous';
    try {
      await _webAudioElement!.play();
    } catch (e2) {
      // Final attempt: fresh element, no crossOrigin, longer delay
      await Future.delayed(const Duration(milliseconds: 300));
      stopWebAudio();
      _webAudioElement = html.AudioElement(url);
      await _webAudioElement!.play();
    }
  }
}

void stopWebAudio() {
  if (_webAudioElement != null) {
    _webAudioElement!.pause();
    _webAudioElement!.currentTime = 0;
    _webAudioElement = null;
  }
}
