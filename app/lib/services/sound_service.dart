import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  // Settings State
  bool _isBgmEnabled = true;
  double _bgmVolume = 0.3;
  bool _isSfxEnabled = true;
  double _sfxVolume = 0.5;

  // For UI updates (backward compatibility + new UI)
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier(false); // Maps to global mute or SFX mute
  
  // Assets
  static const String _bgmAsset = 'audio/bgm/ambient_calm.mp3'; 
  final List<String> _typingSounds = [
    'audio/thock_mid.wav',
    'audio/typing_mid.wav',
  ];
  static const String _enterSound = 'audio/thock_low.wav';
  static const String _spaceSound = 'audio/thock_low.wav';
  static const String _deleteSound = 'audio/thock_high.wav';
  static const String _disabledSound = 'audio/disabled.wav';
  static const String _buttonSound = 'audio/thock_mid.wav'; // Default button sound

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadSettings(prefs);

    // Audio Context Setup
    await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    // Consolidate mute state for backward compatibility
    isMutedNotifier.value = !_isSfxEnabled; 

    // BGM Setup
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    if (_isBgmEnabled) {
      // Intentionally not awaiting play to fast start
      // Note: We need a BGM file. If not present, this will log error but app continues.
      _playBgmInternal();
    }
  }

  Future<void> _loadSettings(SharedPreferences prefs) async {
    _isBgmEnabled = prefs.getBool('bgm_enabled') ?? true;
    _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.3;
    _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.5;
    
    // Legacy support: if 'is_muted' exists, override sfx
    if (prefs.containsKey('is_muted')) {
      bool legacyMuted = prefs.getBool('is_muted') ?? false;
      if (legacyMuted) {
        _isSfxEnabled = false;
        _isBgmEnabled = false; // Usually mute means all mute
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm_enabled', _isBgmEnabled);
    await prefs.setDouble('bgm_volume', _bgmVolume);
    await prefs.setBool('sfx_enabled', _isSfxEnabled);
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('is_muted', !_isSfxEnabled); // Legacy sync
  }

  // --- BGM Control ---

  Future<void> _playBgmInternal() async {
    try {
      if (_bgmPlayer.state == PlayerState.playing) return;
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource(_bgmAsset));
    } catch (e) {
      debugPrint("Error playing BGM: $e");
    }
  }

  Future<void> playBgm() async {
    if (_isBgmEnabled) {
      await _playBgmInternal();
    }
  }

  Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _isBgmEnabled = enabled;
    if (enabled) {
      playBgm();
    } else {
      stopBgm();
    }
    await _saveSettings();
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    if (_isBgmEnabled) {
      await _bgmPlayer.setVolume(_bgmVolume);
    }
    await _saveSettings();
  }

  // --- SFX Control ---

  Future<void> _playSfx(String assetPath, {double? volumeMultiplier}) async {
    if (!_isSfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setVolume(_sfxVolume * (volumeMultiplier ?? 1.0));
      await player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint("Error playing SFX: $e");
    }
  }

  void playTypingSound() {
    final random = Random();
    final sound = _typingSounds[random.nextInt(_typingSounds.length)];
    _playSfx(sound, volumeMultiplier: 0.8);
  }

  void playEnterSound() => _playSfx(_enterSound);
  void playSpaceSound() => _playSfx(_spaceSound);
  void playDeleteSound() => _playSfx(_deleteSound);
  void playDisabledSound() => _playSfx(_disabledSound);
  void playButtonSound() => _playSfx(_buttonSound);

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    isMutedNotifier.value = !enabled; // Sync notifier
    await _saveSettings();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  // Legacy method for backward compatibility
  void toggleMute() {
    bool newState = !_isSfxEnabled; // Toggle logic
    setSfxEnabled(newState);
    setBgmEnabled(newState); // Toggle both for simple mute
  }

  // Getters
  bool get isBgmEnabled => _isBgmEnabled;
  double get bgmVolume => _bgmVolume;
  bool get isSfxEnabled => _isSfxEnabled;
  double get sfxVolume => _sfxVolume;
}
