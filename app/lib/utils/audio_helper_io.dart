import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Native: Play audio from URL with download fallback
/// audioplayers UrlSource can fail silently on some Android devices,
/// so we download to a temp file and play locally as a fallback.
Future<void> playAudioUrl(String url, {AudioPlayer? player}) async {
  final ap = player ?? AudioPlayer();

  try {
    // First attempt: direct URL playback
    debugPrint('[AudioHelper] Trying UrlSource: $url');
    await ap.stop();
    await ap.setSourceUrl(url);
    await ap.resume();
    debugPrint('[AudioHelper] UrlSource playback started');
  } catch (e) {
    debugPrint('[AudioHelper] UrlSource failed: $e, falling back to download');
    // Fallback: download to temp file and play locally
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final ext = url.contains('.webm') ? 'webm' : 'm4a';
        final tempFile = File('${tempDir.path}/voice_temp_${DateTime.now().millisecondsSinceEpoch}.$ext');
        
        final bytes = await response.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        await tempFile.writeAsBytes(bytes);
        debugPrint('[AudioHelper] Downloaded to: ${tempFile.path} (${bytes.length} bytes)');

        await ap.stop();
        await ap.play(DeviceFileSource(tempFile.path));
        debugPrint('[AudioHelper] DeviceFileSource playback started');
      } else {
        debugPrint('[AudioHelper] Download failed: HTTP ${response.statusCode}');
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }
      client.close();
    } catch (downloadErr) {
      debugPrint('[AudioHelper] Download fallback also failed: $downloadErr');
      rethrow;
    }
  }
}

void stopWebAudio() {
  // No-op on native
}
