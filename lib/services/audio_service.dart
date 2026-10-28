import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../core/theme/skin_manager.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    // Evitar que Android requiera interacción del usuario o pelee por el foco de audio
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);

    // Escuchar el ciclo de vida de la app para pausar BGM en segundo plano
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      resumeBgm();
    }
  }

  final AudioPlayer _bgmPlayer = AudioPlayer();
  // Usamos múltiples reproductores para SFX para permitir solapamiento (overlapping)
  final List<AudioPlayer> _sfxPlayers = List.generate(5, (_) => AudioPlayer());
  int _currentSfxIndex = 0;

  bool _prefsLoaded = false;
  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  String _currentTheme = 'party';
  String? _currentBgmTrack;
  String? _activeBgmKey;

  Future<void> _ensurePrefsLoaded() async {
    if (_prefsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_prefsLoaded) {
      _bgmEnabled = prefs.getBool('profileBgmEnabled') ?? true;
      _sfxEnabled = prefs.getBool('profileSfxEnabled') ?? true;
      _currentTheme = prefs.getString('profileSkin') ?? 'party';
      _prefsLoaded = true;
    }
  }

  void updateSettings(GameProvider gameProvider) {
    final String previousTheme = _currentTheme;
    final bool previousBgmEnabled = _bgmEnabled;

    _prefsLoaded = true;
    _bgmEnabled = gameProvider.profileBgmEnabled;
    _sfxEnabled = gameProvider.profileSfxEnabled;
    _currentTheme = gameProvider.profileSkin;

    // Si la música de fondo está apagada, detenerla salvo que estemos en el timelapse de escritura
    if (!_bgmEnabled && _currentBgmTrack != 'timelapse') {
      _activeBgmKey = null;
      _bgmPlayer.stop();
      return;
    }

    // Si cambió el tema o se volvió a activar el BGM y ya había una pista activa (ej. en Home/Perfil), recargarla
    if (_currentBgmTrack != null && (_bgmEnabled || _currentBgmTrack == 'timelapse')) {
      if (previousTheme != _currentTheme ||
          !previousBgmEnabled ||
          _bgmPlayer.state != PlayerState.playing) {
        playBgm(_currentBgmTrack!, forceRestart: previousTheme != _currentTheme);
      }
    }
  }

  /// Permite cambiar el tema activo en tiempo real (por ejemplo al previsualizar en Perfil)
  Future<void> setTheme(String themeId) async {
    await _ensurePrefsLoaded();
    if (_currentTheme == themeId) return;
    _currentTheme = themeId;
    if ((_bgmEnabled || _currentBgmTrack == 'timelapse') && _currentBgmTrack != null) {
      await playBgm(_currentBgmTrack!, forceRestart: true);
    }
  }

  Future<bool> _assetExists(String assetPath, Set<String> manifestAssets) async {
    if (manifestAssets.contains(assetPath)) return true;
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Source?> _resolveAudioSource(String filename) async {
    final theme = SkinManager.getTheme(_currentTheme);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final manifestSet = manifest.listAssets().toSet();

    // 1. Current Theme
    if (theme.isDownloaded && !theme.isBuiltIn && theme.localDirectory != null) {
      final localAudio = File('${theme.localDirectory}/audio/$filename');
      if (localAudio.existsSync()) {
        return DeviceFileSource(localAudio.path);
      }
    }
    
    final themePath = 'assets/themes/$_currentTheme/audio/$filename';
    if (await _assetExists(themePath, manifestSet)) {
      return AssetSource('themes/$_currentTheme/audio/$filename');
    }

    // 2. Default Theme
    final defaultPath = 'assets/themes/default/audio/$filename';
    if (await _assetExists(defaultPath, manifestSet)) {
      return AssetSource('themes/default/audio/$filename');
    }

    // 3. Global Audio
    String globalFilename = filename;
    if (filename == 'ready_3.wav' || filename == 'ready_2.wav' || filename == 'ready_1.wav') {
      if (!await _assetExists('assets/global/audio/$filename', manifestSet)) {
        globalFilename = 'ready_beep.wav';
      }
    }

    final globalPath = 'assets/global/audio/$globalFilename';
    if (await _assetExists(globalPath, manifestSet)) {
      return AssetSource('global/audio/$globalFilename');
    }

    return null; // Not found anywhere
  }

  Future<void> playBgm(String trackName, {String ext = '.mp3', bool forceRestart = false}) async {
    await _ensurePrefsLoaded();
    _currentBgmTrack = trackName;

    // La música del timelapse (mientras escriben las palabras) se mantiene siempre activa
    // aunque el switch de música de fondo (_bgmEnabled) esté apagado.
    final bool shouldPlay = _bgmEnabled || trackName == 'timelapse';
    if (!shouldPlay) {
      _activeBgmKey = null;
      await _bgmPlayer.stop();
      return;
    }

    final String targetKey = '$_currentTheme:$trackName$ext';
    if (!forceRestart && _activeBgmKey == targetKey && _bgmPlayer.state == PlayerState.playing) {
      return;
    }

    try {
      _activeBgmKey = targetKey;
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      final source = await _resolveAudioSource('$trackName$ext');
      if (source != null) {
        await _bgmPlayer.play(source);
      }
    } catch (e) {
      debugPrint("BGM error: $e");
    }
  }

  void stopBgm() {
    _activeBgmKey = null;
    _bgmPlayer.stop();
  }

  void pauseBgm() {
    _bgmPlayer.pause();
  }

  void resumeBgm() {
    if ((_bgmEnabled || _currentBgmTrack == 'timelapse') && _currentBgmTrack != null) {
      _bgmPlayer.resume();
    }
  }

  Future<void> playSfx(String soundName) async {
    await _ensurePrefsLoaded();
    if (!_sfxEnabled) return;

    final player = _sfxPlayers[_currentSfxIndex];
    _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPlayers.length;

    try {
      final source = await _resolveAudioSource('$soundName.wav');
      if (source != null) {
        await player.play(source);
      }
    } catch (e) {
      debugPrint("SFX error: $e");
    }
  }

  /// Sonido retro de moneda 8-bits exclusivo para el intro de Caduceo Antigravity Studio
  Future<void> playStudioCoin() async {
    await _ensurePrefsLoaded();
    if (!_sfxEnabled) return;

    final player = _sfxPlayers[_currentSfxIndex];
    _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPlayers.length;

    try {
      await player.play(AssetSource('global/audio/studio_coin.wav'));
    } catch (e) {
      debugPrint("Studio coin SFX error: $e");
    }
  }

  // Métodos de conveniencia
  void playClickMajor() => playSfx('playClickMajor');
  void playClickMinor() => playSfx('playClickMinor');
  void playRoulette() => playSfx('roulette');
  void playTick() => playSfx('tick');
  void playCountdown() => playSfx('countdown');
  void playReady(int count) => playSfx('ready_$count');
  void playReadyGo() => playSfx('ready_go');
  void playError() => playSfx('error');

  void playThemeBell() => playSfx('start_bell');

  /// Reproduce el audio general de "¡BASTA!" en todos los temas
  Future<void> playThemeAlarm() async {
    await _ensurePrefsLoaded();
    if (!_sfxEnabled) return;
    final player = _sfxPlayers[_currentSfxIndex];
    _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPlayers.length;
    try {
      await player.play(AssetSource('themes/default/audio/basta_alarm.wav'));
    } catch (e) {
      debugPrint("Basta alarm SFX error: $e");
    }
  }

  void playThemeNextRound() => playSfx('next_round');
}
