import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  late AudioPlayer _player;
  bool _isMuted = false;
  
  // Expose mute state for UI
  ValueNotifier<bool> isMutedNotifier = ValueNotifier(false);

  Future<void> init() async {
    _player = AudioPlayer();
    
    // Load Mute State
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('is_muted') ?? false;
    isMutedNotifier.value = _isMuted;
    
    // Preload Critical Sounds
    // Note: AudioPlayers load automatically on play usually, but pre-cache helps latency.
    // However, AudioCache is deprecated in v6, we use AudioPlayer directly with AssetSource.
    // We can 'warm up' by playing silent or low volume? No, v6 is better.
  }

  Future<void> playButtonSound() async {
    if (_isMuted) return;
    try {
      // Pick a random sound variation for natural feel
      final variants = ['thock_high.wav', 'thock_mid.wav', 'thock_low.wav'];
      final chosen = (variants..shuffle()).first;
      
      final player = AudioPlayer();
      await player.play(AssetSource('audio/$chosen'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> playDisabledSound() async {
    if (_isMuted) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/disabled.wav'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> playTypingSound() async {
    if (_isMuted) return;
    try {
      final variants = ['typing_high.wav', 'typing_mid.wav'];
      final chosen = (variants..shuffle()).first;
      
      final player = AudioPlayer();
      // Lower volume for typing to not be annoying
      await player.setVolume(0.5); 
      await player.play(AssetSource('audio/$chosen'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  void toggleMute() async {
    _isMuted = !_isMuted;
    isMutedNotifier.value = _isMuted;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_muted', _isMuted);
  }
}
