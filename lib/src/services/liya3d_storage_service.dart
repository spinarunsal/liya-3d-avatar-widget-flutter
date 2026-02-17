import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting session data
class Liya3dStorageService {
  static const String _sessionIdKey = 'liya3d_session_id';
  static const String _localeKey = 'liya3d_locale';
  static const String _lastAssistantIdKey = 'liya3d_last_assistant_id';

  SharedPreferences? _prefs;
  final String? assistantId;

  Liya3dStorageService({this.assistantId});

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get storage key with assistant ID prefix
  String _getKey(String baseKey) {
    if (assistantId != null) {
      return '${baseKey}_$assistantId';
    }
    return baseKey;
  }

  /// Get saved session ID
  Future<String?> getSessionId() async {
    await init();
    return _prefs?.getString(_getKey(_sessionIdKey));
  }

  /// Save session ID
  Future<void> saveSessionId(String sessionId) async {
    await init();
    await _prefs?.setString(_getKey(_sessionIdKey), sessionId);
  }

  /// Clear session ID
  Future<void> clearSessionId() async {
    await init();
    await _prefs?.remove(_getKey(_sessionIdKey));
  }

  /// Get saved locale
  Future<String?> getLocale() async {
    await init();
    return _prefs?.getString(_localeKey);
  }

  /// Save locale
  Future<void> saveLocale(String locale) async {
    await init();
    await _prefs?.setString(_localeKey, locale);
  }

  /// Get last used assistant ID
  Future<String?> getLastAssistantId() async {
    await init();
    return _prefs?.getString(_lastAssistantIdKey);
  }

  /// Save last used assistant ID
  Future<void> saveLastAssistantId(String assistantId) async {
    await init();
    await _prefs?.setString(_lastAssistantIdKey, assistantId);
  }

  /// Clear all stored data for current assistant
  Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_getKey(_sessionIdKey));
  }

  /// Clear all Liya3d data
  Future<void> clearAllData() async {
    await init();
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('liya3d_')) {
        await _prefs?.remove(key);
      }
    }
  }
}
