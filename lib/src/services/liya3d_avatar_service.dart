import '../models/liya3d_api_response.dart';
import '../models/liya3d_avatar_speech.dart';
import 'liya3d_api_service.dart';

/// Avatar-specific service wrapper
/// Handles avatar model loading, speech generation, and access control
class Liya3dAvatarService {
  final Liya3dApiService _apiService;

  /// Cached user access response
  Liya3dUserAccessResponse? _cachedAccess;

  /// Cached avatar model response
  Liya3dAvatarModelResponse? _cachedModel;

  /// Custom avatar model URL (from config)
  final String? customModelUrl;

  Liya3dAvatarService({
    required Liya3dApiService apiService,
    this.customModelUrl,
  }) : _apiService = apiService;

  /// Check if user has avatar access
  Future<bool> checkAccess({bool forceRefresh = false}) async {
    if (_cachedAccess != null && !forceRefresh) {
      return _cachedAccess!.hasAvatarAccess;
    }

    final response = await _apiService.checkUserAccess();
    if (response.success && response.data != null) {
      _cachedAccess = response.data;
      return _cachedAccess!.hasAvatarAccess;
    }

    return false;
  }

  /// Get cached access response
  Liya3dUserAccessResponse? get accessInfo => _cachedAccess;

  /// Get avatar model URL
  Future<String?> getModelUrl({bool forceRefresh = false}) async {
    // If custom URL is provided, use it
    if (customModelUrl != null && customModelUrl!.isNotEmpty) {
      return customModelUrl;
    }

    // Check cache
    if (_cachedModel != null && !forceRefresh) {
      return _cachedModel!.effectiveModelUrl;
    }

    // Fetch from API
    final response = await _apiService.getAvatarModel();
    if (response.success && response.data != null) {
      _cachedModel = response.data;
      return _cachedModel!.effectiveModelUrl;
    }

    return null;
  }

  /// Get cached model response
  Liya3dAvatarModelResponse? get modelInfo => _cachedModel;

  /// Generate speech with visemes for lip-sync
  Future<Liya3dApiResponse<Liya3dAvatarSpeechResponse>> generateSpeech(
    String text, {
    String voice = 'nova',
    double speed = 1.0,
  }) {
    return _apiService.generateAvatarSpeech(text, voice: voice, speed: speed);
  }

  /// Generate TTS audio only
  Future<Liya3dApiResponse<String>> generateTts(
    String text, {
    String voice = 'nova',
    double speed = 1.0,
  }) {
    return _apiService.generateTts(text, voice: voice, speed: speed);
  }

  /// Clear cached data
  void clearCache() {
    _cachedAccess = null;
    _cachedModel = null;
  }
}
