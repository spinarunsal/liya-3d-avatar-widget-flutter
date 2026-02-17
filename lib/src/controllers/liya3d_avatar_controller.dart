import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/liya3d_enums.dart';
import '../models/liya3d_avatar_speech.dart';
import '../services/liya3d_audio_service.dart';
import '../services/liya3d_avatar_service.dart';

/// Avatar WebView controller
/// Manages Three.js scene via JavaScript bridge
class Liya3dAvatarController extends ChangeNotifier {
  final Liya3dAvatarService _avatarService;
  final Liya3dAudioService _audioService;

  InAppWebViewController? _webViewController;

  /// Current avatar status
  Liya3dAvatarStatus _status = Liya3dAvatarStatus.idle;
  Liya3dAvatarStatus get status => _status;

  /// Whether avatar model is loaded
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  /// Whether WebView is ready
  bool _isWebViewReady = false;
  bool get isWebViewReady => _isWebViewReady;

  /// Current model URL
  String? _modelUrl;
  String? get modelUrl => _modelUrl;

  /// Error message
  String? _error;
  String? get error => _error;

  /// Whether currently speaking
  bool get isSpeaking => _status == Liya3dAvatarStatus.speaking;

  /// Whether currently preparing
  bool get isPreparing => _status == Liya3dAvatarStatus.preparing;

  /// Callback when avatar starts speaking
  void Function()? onSpeakingStarted;

  /// Callback when avatar stops speaking
  void Function()? onSpeakingEnded;

  /// Callback when model is loaded
  void Function()? onModelLoaded;

  /// Callback on error
  void Function(String error)? onError;

  /// Position update subscription
  StreamSubscription<Duration>? _positionSubscription;

  Liya3dAvatarController({
    required Liya3dAvatarService avatarService,
    required Liya3dAudioService audioService,
  })  : _avatarService = avatarService,
        _audioService = audioService {
    _setupAudioCallbacks();
  }

  void _setupAudioCallbacks() {
    _audioService.onStart = () {
      _setStatus(Liya3dAvatarStatus.speaking);
      _evaluateJs('window.liya3dAvatar?.setSpeaking(true)');
      onSpeakingStarted?.call();
    };

    _audioService.onComplete = () {
      _setStatus(Liya3dAvatarStatus.idle);
      _evaluateJs('window.liya3dAvatar?.setSpeaking(false)');
      onSpeakingEnded?.call();
    };

    _audioService.onPositionUpdate = (currentTime) {
      _evaluateJs('window.liya3dAvatar?.updateCurrentTime($currentTime)');
    };
  }

  /// Set WebView controller
  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _isWebViewReady = true;
    notifyListeners();
  }

  /// Called when WebView page is loaded
  Future<void> onWebViewReady() async {
    _isWebViewReady = true;

    // Load avatar model
    await _loadModel();

    notifyListeners();
  }

  /// Load avatar model
  Future<void> _loadModel() async {
    if (!_isWebViewReady) return;

    _modelUrl = await _avatarService.getModelUrl();

    if (_modelUrl != null && _modelUrl!.isNotEmpty) {
      var url = _modelUrl!;
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
      await _evaluateJs('window.loadAvatarModel("$url")');
    } else {
      await _evaluateJs('window.liya3dAvatar?.createDefaultAvatar()');
    }
  }

  /// Reload avatar model
  Future<void> reloadModel({String? customUrl}) async {
    if (customUrl != null) {
      _modelUrl = customUrl;
    } else {
      _modelUrl = await _avatarService.getModelUrl(forceRefresh: true);
    }

    if (_modelUrl != null && _isWebViewReady) {
      var url = _modelUrl!;
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
      await _evaluateJs('window.liya3dAvatar?.loadModel("$url")');
    }
  }

  /// Called from JavaScript when model is loaded
  void onAvatarLoaded() {
    _isModelLoaded = true;
    _error = null;
    onModelLoaded?.call();
    notifyListeners();
  }

  /// Called from JavaScript when model loading fails
  void onAvatarError(String error) {
    _error = error;
    _isModelLoaded = false;
    onError?.call(error);
    notifyListeners();
  }

  /// Speak text with avatar lip-sync
  Future<bool> speak(String text, {String voice = 'nova', double speed = 1.0}) async {
    if (text.isEmpty) return false;

    _setStatus(Liya3dAvatarStatus.preparing);
    notifyListeners();

    // Generate speech with visemes
    final response = await _avatarService.generateSpeech(
      text,
      voice: voice,
      speed: speed,
    );

    if (!response.success || response.data == null) {
      _setStatus(Liya3dAvatarStatus.idle);
      _error = response.error;
      notifyListeners();
      return false;
    }

    final speechData = response.data!;

    // Send visemes to WebView BEFORE audio starts
    if (speechData.visemes.isNotEmpty) {
      final visemesJson = jsonEncode(speechData.visemes.map((v) => v.toJson()).toList());
      await _evaluateJs('window.liya3dAvatar?.updateVisemes($visemesJson)');
    }

    // Play audio (this will trigger status changes via callbacks)
    final played = await _audioService.playAvatarSpeech(speechData);

    if (!played) {
      _setStatus(Liya3dAvatarStatus.idle);
      return false;
    }

    return true;
  }

  /// Speak with pre-generated speech data (for typewriter sync)
  Future<bool> speakWithData(Liya3dAvatarSpeechResponse speechData) async {
    _setStatus(Liya3dAvatarStatus.preparing);
    notifyListeners();

    if (speechData.visemes.isNotEmpty) {
      final visemesJson = jsonEncode(speechData.visemes.map((v) => v.toJson()).toList());
      await _evaluateJs('window.liya3dAvatar?.updateVisemes($visemesJson)');
    }

    final played = await _audioService.playAvatarSpeech(speechData);

    if (!played) {
      _setStatus(Liya3dAvatarStatus.idle);
      return false;
    }

    return true;
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _audioService.stop();
    _setStatus(Liya3dAvatarStatus.idle);
    await _evaluateJs('window.liya3dAvatar?.setSpeaking(false)');
    notifyListeners();
  }

  /// Set listening status (for kiosk mode)
  void setListening(bool isListening) {
    if (isListening) {
      _setStatus(Liya3dAvatarStatus.listening);
    } else if (_status == Liya3dAvatarStatus.listening) {
      _setStatus(Liya3dAvatarStatus.idle);
    }
    notifyListeners();
  }

  /// Update WebView size
  Future<void> setSize(double width, double height) async {
    await _evaluateJs('window.liya3dAvatar?.setSize($width, $height)');
  }

  /// Cleanup WebView resources
  Future<void> cleanup() async {
    await _evaluateJs('window.liya3dAvatar?.cleanup()');
  }

  void _setStatus(Liya3dAvatarStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<void> _evaluateJs(String script) async {
    if (_webViewController != null && _isWebViewReady) {
      try {
        await _webViewController!.evaluateJavascript(source: script);
      } catch (_) {}
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    cleanup();
    super.dispose();
  }
}
