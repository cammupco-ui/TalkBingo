import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';

html.AudioElement? _webAudioElement;

/// Web: Use HTML5 Audio element directly to avoid audioplayers AbortError
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  // Stop any existing playback
  stopWebAudio();
  
  _webAudioElement = html.AudioElement(url);
  _webAudioElement!.crossOrigin = 'anonymous';
  
  try {
    await _webAudioElement!.play();
  } catch (e) {
    // If crossOrigin fails, try without it
    _webAudioElement = html.AudioElement(url);
    await _webAudioElement!.play();
  }
}

void stopWebAudio() {
  if (_webAudioElement != null) {
    _webAudioElement!.pause();
    _webAudioElement!.currentTime = 0;
    _webAudioElement = null;
  }
}
