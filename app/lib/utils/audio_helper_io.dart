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
    try {
      await _voicePlayer?.stop();
      await _voicePlayer?.dispose();
    } catch (e) {
      debugPrint('[AudioHelper] Cleanup error (ignored): $e');
    }
    _voicePlayer = ja.AudioPlayer();

    debugPrint('[AudioHelper] Downloading: $url');

    // 2) Download the audio file
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 10);
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

    if (bytes.isEmpty) {
      throw Exception('Downloaded file is empty');
    }

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
    // On iOS, we need to set the audio source first, then play.
    // The just_audio package handles iOS audio session configuration internally.
    final duration = await _voicePlayer!.setFilePath(tempFile.path);
    debugPrint('[AudioHelper] Audio duration: $duration');
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
    // On iOS, if audio session conflict occurs, try once more with a fresh player
    if (e.toString().contains('AudioSession') || 
        e.toString().contains('AVPlayerItem') ||
        e.toString().contains('PlayerException')) {
      debugPrint('[AudioHelper] Retrying with fresh player...');
      try {
        await _voicePlayer?.dispose();
        _voicePlayer = ja.AudioPlayer();
        
        // Try direct URL as fallback (some iOS versions handle this better)
        await _voicePlayer!.setUrl(url);
        await _voicePlayer!.play();
        debugPrint('[AudioHelper] Retry playback succeeded');
        return;
      } catch (retryError) {
        debugPrint('[AudioHelper] Retry also failed: $retryError');
      }
    }
    rethrow;
  }
}

void stopWebAudio() {
  _voicePlayer?.stop();
}
