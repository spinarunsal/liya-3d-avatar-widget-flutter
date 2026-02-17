import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/liya3d_api_response.dart';
import '../models/liya3d_avatar_speech.dart';

/// HTTP client for Liya API calls
/// Matches Vue.js api/client.ts + chat.ts + avatar.ts
class Liya3dApiService {
  final String baseUrl;
  final String apiKey;
  final String assistantId;
  final Duration timeout;

  late final Map<String, String> _headers;
  late final http.Client _client;

  Liya3dApiService({
    required this.baseUrl,
    required this.apiKey,
    required this.assistantId,
    this.timeout = const Duration(seconds: 60),
  }) {
    _headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'User-Agent': _getPlatformUserAgent(),
    };
    _client = http.Client();
  }

  /// Get platform-specific User-Agent string
  /// iOS: Safari UA to get mp3 format (opus not supported)
  /// Android: Chrome UA to get opus/mp3 format
  String _getPlatformUserAgent() {
    if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
    } else if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    } else {
      // Default fallback for other platforms
      return 'Mozilla/5.0 (compatible; Liya3dWidget/1.0)';
    }
  }

  /// Clean base URL (remove trailing slash)
  String get _cleanBaseUrl => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  /// Make GET request
  Future<Liya3dApiResponse<Map<String, dynamic>>> _get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_cleanBaseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _client.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Liya3dApiResponse.success(data);
      } else {
        final error = _parseError(response);
        return Liya3dApiResponse.failure(error, statusCode: response.statusCode);
      }
    } on SocketException {
      return Liya3dApiResponse.failure('Network error. Please check your connection.');
    } catch (e) {
      return Liya3dApiResponse.failure(e.toString());
    }
  }

  /// Make POST request
  Future<Liya3dApiResponse<Map<String, dynamic>>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl$endpoint');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Liya3dApiResponse.success(data);
      } else {
        final error = _parseError(response);
        return Liya3dApiResponse.failure(error, statusCode: response.statusCode);
      }
    } on SocketException {
      return Liya3dApiResponse.failure('Network error. Please check your connection.');
    } catch (e) {
      return Liya3dApiResponse.failure(e.toString());
    }
  }

  /// Parse error message from response
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['error'] as String? ??
            data['message'] as String? ??
            data['detail'] as String? ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}';
  }

  // ============================================================
  // Chat API (chat.ts)
  // ============================================================

  /// Send a chat message
  /// POST /api/v1/external/chat/
  Future<Liya3dApiResponse<Liya3dSendMessageResponse>> sendMessage(
    String message, {
    String? sessionId,
    List<String>? fileIds,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'assistant_id': assistantId,
    };

    if (sessionId != null && sessionId.isNotEmpty) {
      body['session_id'] = sessionId;
    }

    if (fileIds != null && fileIds.isNotEmpty) {
      body['file_ids'] = fileIds;
    }

    final response = await _post('/api/v1/external/chat/', body);

    if (response.success && response.data != null) {
      Map<String, dynamic> responseData = response.data!;
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        responseData = responseData['data'] as Map<String, dynamic>;
      }
      
      return Liya3dApiResponse.success(
        Liya3dSendMessageResponse.fromJson(responseData),
      );
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to send message',
      statusCode: response.statusCode,
    );
  }

  /// Get session history
  /// GET /api/v1/external/sessions/{sessionId}/history/
  Future<Liya3dApiResponse<Liya3dSessionHistoryResponse>> getSessionHistory(
    String sessionId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/api/v1/external/sessions/$sessionId/history/',
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    if (response.success && response.data != null) {
      return Liya3dApiResponse.success(
        Liya3dSessionHistoryResponse.fromJson(response.data!),
      );
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to load history',
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // Avatar API (avatar.ts)
  // ============================================================

  /// Check user access for avatar features
  /// GET /api/v1/external/user/access/
  Future<Liya3dApiResponse<Liya3dUserAccessResponse>> checkUserAccess() async {
    final response = await _get(
      '/api/v1/external/user/access/',
      queryParams: {'assistant_id': assistantId},
    );

    if (response.success && response.data != null) {
      return Liya3dApiResponse.success(
        Liya3dUserAccessResponse.fromJson(response.data!),
      );
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to check access',
      statusCode: response.statusCode,
    );
  }

  /// Get avatar model URL
  /// GET /api/v1/external/avatar/model/
  Future<Liya3dApiResponse<Liya3dAvatarModelResponse>> getAvatarModel({
    String? customAssistantId,
  }) async {
    final response = await _get(
      '/api/v1/external/avatar/model/',
      queryParams: {'assistant_id': customAssistantId ?? assistantId},
    );

    if (response.success && response.data != null) {
      return Liya3dApiResponse.success(
        Liya3dAvatarModelResponse.fromJson(response.data!),
      );
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to get avatar model',
      statusCode: response.statusCode,
    );
  }

  /// Generate avatar speech with visemes
  /// POST /api/v1/external/avatar/speech/
  /// Matches Vue.js widget speakWithAvatar() function
  Future<Liya3dApiResponse<Liya3dAvatarSpeechResponse>> generateAvatarSpeech(
    String text, {
    String voice = 'nova',
    double speed = 1.0,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'voice': voice,
      'speed': speed,
      'include_audio': true, // Required for audio generation (Vue.js widget)
      'output_format': 'mp3', // iOS doesn't support opus, use mp3
      'assistant_id': assistantId,
    };

    final response = await _post('/api/v1/external/avatar/speech/', body);

    if (response.success && response.data != null) {
      Map<String, dynamic> responseData = response.data!;
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        responseData = responseData['data'] as Map<String, dynamic>;
      }
      
      return Liya3dApiResponse.success(
        Liya3dAvatarSpeechResponse.fromJson(responseData),
      );
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to generate speech',
      statusCode: response.statusCode,
    );
  }

  /// Generate TTS audio only (no visemes)
  /// POST /api/v1/external/tts/
  Future<Liya3dApiResponse<String>> generateTts(
    String text, {
    String voice = 'nova',
    double speed = 1.0,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'voice': voice,
      'speed': speed,
      'assistant_id': assistantId,
    };

    final response = await _post('/api/v1/external/tts/', body);

    if (response.success && response.data != null) {
      final audioBase64 = response.data!['audio_base64'] as String? ??
          response.data!['audio'] as String?;
      if (audioBase64 != null) {
        return Liya3dApiResponse.success(audioBase64);
      }
    }

    return Liya3dApiResponse.failure(
      response.error ?? 'Failed to generate TTS',
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // File API (files.ts)
  // ============================================================

  /// Upload a file
  /// POST /api/v1/external/files/upload/
  Future<Liya3dApiResponse<Liya3dFileUploadResponse>> uploadFile(
    String filePath,
    String fileName,
    String mimeType,
  ) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/v1/external/files/upload/');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'X-API-Key': apiKey,
      });

      request.fields['assistant_id'] = assistantId;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      ));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Liya3dApiResponse.success(
          Liya3dFileUploadResponse.fromJson(data),
        );
      } else {
        final error = _parseError(response);
        return Liya3dApiResponse.failure(error, statusCode: response.statusCode);
      }
    } catch (e) {
      return Liya3dApiResponse.failure(e.toString());
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
