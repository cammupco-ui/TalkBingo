import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Native: Try multiple playback strategies for cross-platform audio compatibility.
/// Web clients send Opus/WebM which Android's MediaPlayer may not handle via DeviceFileSource.
/// Strategy: UrlSource first (ExoPlayer handles WebM/Opus well via URL streaming),
/// then fallback to DeviceFileSource for local files.
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  final ap = player ?? AudioPlayer();

  try {
    debugPrint('[AudioHelper] Playing audio: $url');
    
    // Strategy 1: Play directly via UrlSource
    // Android's ExoPlayer (used by audioplayers for URL sources) handles
    // WebM/Opus well when Content-Type headers are available from the server.
    await ap.stop();
    await ap.setSourceUrl(url);
    await ap.resume();
    debugPrint('[AudioHelper] UrlSource playback started');
  } catch (e) {
    debugPrint('[AudioHelper] UrlSource failed: $e, trying DeviceFileSource...');
    
    // Strategy 2: Download and play locally
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        // Detect format from URL for correct file extension
        final ext = url.contains('.webm') ? 'webm' 
                   : url.contains('.ogg') ? 'ogg' 
                   : 'm4a';
        final tempFile = File('${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.$ext');

        final bytes = await response.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        await tempFile.writeAsBytes(bytes);
        debugPrint('[AudioHelper] Downloaded to: ${tempFile.path} (${bytes.length} bytes)');

        await ap.stop();
        await ap.play(DeviceFileSource(tempFile.path));
        debugPrint('[AudioHelper] DeviceFileSource playback started');
      } else {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }
      client.close();
    } catch (e2) {
      debugPrint('[AudioHelper] DeviceFileSource also failed: $e2');
      rethrow;
    }
  }
}

void stopWebAudio() {
  // No-op on native
}
