import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice input controller using speech_to_text
class Liya3dVoiceController extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  /// Whether speech recognition is available
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Whether currently listening
  bool _isListening = false;
  bool get isListening => _isListening;

  /// Current transcript
  String _transcript = '';
  String get transcript => _transcript;

  /// Final transcript (after stop)
  String _finalTranscript = '';
  String get finalTranscript => _finalTranscript;

  /// Flag to prevent duplicate onComplete calls
  bool _completeCalled = false;

  /// Error message
  String? _error;
  String? get error => _error;

  /// Current locale for recognition
  String _locale = 'tr_TR';
  String get locale => _locale;

  /// Callback when transcript updates
  void Function(String transcript)? onTranscriptUpdate;

  /// Callback when recognition completes
  void Function(String finalTranscript)? onComplete;

  /// Callback on error
  void Function(String error)? onError;

  /// Initialize speech recognition
  Future<bool> init({String? locale}) async {
    if (locale != null) {
      _locale = locale == 'tr' ? 'tr_TR' : 'en_US';
    }

    try {
      // Request microphone permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          _error = 'Microphone permission denied';
          _isAvailable = false;
          notifyListeners();
          return false;
        }
      }
      
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _error = e.toString();
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Set locale
  void setLocale(String locale) {
    _locale = locale == 'tr' ? 'tr_TR' : 'en_US';
  }

  /// Start listening
  Future<bool> startListening() async {
    if (!_isAvailable) {
      final initialized = await init();
      if (!initialized) return false;
    }

    if (_isListening) return true;

    _transcript = '';
    _finalTranscript = '';
    _error = null;
    _completeCalled = false;

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: _locale,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );

      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      onError?.call(_error!);
      notifyListeners();
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    _finalTranscript = _transcript;

    // Only call onComplete once
    if (_finalTranscript.isNotEmpty && !_completeCalled) {
      _completeCalled = true;
      onComplete?.call(_finalTranscript);
    }

    notifyListeners();
  }

  /// Cancel listening (discard transcript)
  Future<void> cancelListening() async {
    if (!_isListening) return;

    await _speech.cancel();
    _isListening = false;
    _transcript = '';
    _finalTranscript = '';
    notifyListeners();
  }

  void _onResult(SpeechRecognitionResult result) {
    _transcript = result.recognizedWords;
    onTranscriptUpdate?.call(_transcript);

    if (result.finalResult) {
      _finalTranscript = _transcript;
      _isListening = false;
      // Only call onComplete once
      if (!_completeCalled && _finalTranscript.isNotEmpty) {
        _completeCalled = true;
        onComplete?.call(_finalTranscript);
      }
    }

    notifyListeners();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _isListening = false;
        _finalTranscript = _transcript;
        // Only call onComplete once
        if (_finalTranscript.isNotEmpty && !_completeCalled) {
          _completeCalled = true;
          onComplete?.call(_finalTranscript);
        }
        notifyListeners();
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    _error = error.errorMsg;
    _isListening = false;
    onError?.call(_error!);
    notifyListeners();
  }

  /// Check if speech recognition permission is granted
  Future<bool> hasPermission() async {
    return _speech.hasPermission;
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) {
      await init();
    }
    return _speech.locales();
  }

  /// Clear transcript
  void clearTranscript() {
    _transcript = '';
    _finalTranscript = '';
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
