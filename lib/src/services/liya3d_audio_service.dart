import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/liya3d_avatar_speech.dart';

/// Audio playback service for avatar speech
/// Uses native audio (just_audio) instead of WebView AudioContext for iOS reliability
class Liya3dAudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Current audio position stream
  Stream<Duration> get positionStream => _player.positionStream;

  /// Current playback state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Whether audio is currently playing
  bool get isPlaying => _player.playing;

  /// Current position in seconds
  double get currentTimeSeconds => _player.position.inMilliseconds / 1000.0;

  /// Total duration in seconds
  double get durationSeconds => (_player.duration?.inMilliseconds ?? 0) / 1000.0;

  /// Callback for position updates (for lip-sync)
  void Function(double currentTime)? onPositionUpdate;

  /// Callback when playback completes
  void Function()? onComplete;

  /// Callback when playback starts
  void Function()? onStart;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  /// Safety timeout timer
  Timer? _safetyTimer;

  /// Current viseme data for lip-sync
  List<Liya3dVisemeData>? _currentVisemes;

  Liya3dAudioService() {
    _setupListeners();
  }

  void _setupListeners() {
    // Position updates for lip-sync
    _positionSubscription = _player.positionStream.listen((position) {
      final currentTime = position.inMilliseconds / 1000.0;
      onPositionUpdate?.call(currentTime);
    });

    // Playback state changes
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _safetyTimer?.cancel();
        onComplete?.call();
      }
    });
  }

  /// Play audio from base64 encoded data
  Future<bool> playBase64Audio(
    String base64Audio, {
    String format = 'mp3',
    double? expectedDuration,
    List<Liya3dVisemeData>? visemes,
  }) async {
    try {
      _currentVisemes = visemes;

      final bytes = base64Decode(base64Audio);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/liya3d_speech_${DateTime.now().millisecondsSinceEpoch}.$format');
      await tempFile.writeAsBytes(bytes);

      await _player.setFilePath(tempFile.path);

      // Setup safety timeout (audio duration + 500ms buffer)
      final duration = expectedDuration ?? durationSeconds;
      if (duration > 0) {
        _safetyTimer?.cancel();
        _safetyTimer = Timer(
          Duration(milliseconds: ((duration + 0.5) * 1000).toInt()),
          () {
            if (isPlaying) {
              stop();
            }
          },
        );
      }

      onStart?.call();
      await _player.play();

      // Clean up temp file after playback
      _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      ).then((_) {
        tempFile.delete().catchError((_) {});
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Play from avatar speech response
  Future<bool> playAvatarSpeech(Liya3dAvatarSpeechResponse speech) async {
    if (!speech.hasAudio) return false;

    return playBase64Audio(
      speech.audioBase64!,
      format: speech.audioFormat ?? 'mp3',
      expectedDuration: speech.duration,
      visemes: speech.visemes,
    );
  }

  /// Get current viseme based on audio position
  Liya3dVisemeData? getCurrentViseme(double currentTime) {
    if (_currentVisemes == null || _currentVisemes!.isEmpty) return null;

    // Find the viseme that matches current time
    for (int i = _currentVisemes!.length - 1; i >= 0; i--) {
      if (_currentVisemes![i].time <= currentTime) {
        return _currentVisemes![i];
      }
    }

    return _currentVisemes!.first;
  }

  /// Stop playback
  Future<void> stop() async {
    _safetyTimer?.cancel();
    await _player.stop();
    onComplete?.call();
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Dispose resources
  void dispose() {
    _safetyTimer?.cancel();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
  }
}
