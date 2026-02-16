import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Keep import for signature compat

/// Dedicated just_audio player for voice messages.
/// ExoPlayer (Android) / AVPlayer (iOS) with local-file strategy
/// to avoid Supabase URL redirect/content-type playback issues.
ja.AudioPlayer? _voicePlayer;

/// Native: Download audio → save to temp file → play via just_audio.
/// This avoids URL redirect, CORS, and content-type issues with Supabase storage.
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  try {
    // 1) Stop & dispose any previous playback
    await _voicePlayer?.stop();
    await _voicePlayer?.dispose();
    _voicePlayer = ja.AudioPlayer();

    debugPrint('[AudioHelper] Downloading: $url');

    // 2) Download the audio file
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      httpClient.close();
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    // Read all bytes
    final chunks = <List<int>>[];
    await response.forEach((chunk) => chunks.add(chunk));
    final bytes = chunks.expand((c) => c).toList();
    httpClient.close();

    debugPrint('[AudioHelper] Downloaded ${bytes.length} bytes');

    // 3) Save to temp file with correct extension
    final dir = await getTemporaryDirectory();
    final ext = url.contains('.webm')
        ? 'webm'
        : url.contains('.ogg')
            ? 'ogg'
            : 'm4a';
    final tempFile = File(
      '${dir.path}/voice_play_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await tempFile.writeAsBytes(bytes);

    debugPrint('[AudioHelper] Saved to: ${tempFile.path}');

    // 4) Play from local file — no URL issues
    await _voicePlayer!.setFilePath(tempFile.path);
    await _voicePlayer!.play();
    debugPrint('[AudioHelper] Playback started (local file)');

    // 5) Clean up temp file after playback completes
    _voicePlayer!.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed) {
        tempFile.delete().catchError((_) => tempFile);
      }
    });
  } catch (e) {
    debugPrint('[AudioHelper] Playback error: $e');
    rethrow;
  }
}

void stopWebAudio() {
  _voicePlayer?.stop();
}
