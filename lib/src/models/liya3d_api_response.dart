import 'liya3d_message.dart';
import 'liya3d_enums.dart';

/// Generic API response wrapper
class Liya3dApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  const Liya3dApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory Liya3dApiResponse.success(T data) {
    return Liya3dApiResponse(success: true, data: data);
  }

  factory Liya3dApiResponse.failure(String error, {int? statusCode}) {
    return Liya3dApiResponse(success: false, error: error, statusCode: statusCode);
  }
}

/// Response from /api/v1/external/chat/ endpoint
class Liya3dSendMessageResponse {
  /// Session ID (created or existing)
  final String sessionId;

  /// Message ID
  final String? messageId;

  /// Raw response text
  final String? response;

  /// Response time in seconds
  final double? responseTime;

  /// User message object
  final Liya3dMessage? userMessage;

  /// Assistant message object
  final Liya3dMessage? assistantMessage;

  /// Suggestion buttons
  final List<String>? suggestions;

  const Liya3dSendMessageResponse({
    required this.sessionId,
    this.messageId,
    this.response,
    this.responseTime,
    this.userMessage,
    this.assistantMessage,
    this.suggestions,
  });

  factory Liya3dSendMessageResponse.fromJson(Map<String, dynamic> json) {
    List<String>? suggestions;
    
    // Parse suggestions from assistant_message or root level
    if (json['assistant_message'] != null) {
      final assistantMsg = json['assistant_message'] as Map<String, dynamic>;
      if (assistantMsg['suggestions'] != null) {
        suggestions = List<String>.from(assistantMsg['suggestions'] as List);
      }
    }
    if (suggestions == null && json['suggestions'] != null) {
      suggestions = List<String>.from(json['suggestions'] as List);
    }

    return Liya3dSendMessageResponse(
      sessionId: json['session_id'] as String? ?? '',
      messageId: json['message_id'] as String?,
      response: json['response'] as String?,
      responseTime: json['response_time'] != null
          ? (json['response_time'] as num).toDouble()
          : null,
      userMessage: json['user_message'] != null
          ? Liya3dMessage.fromJson(json['user_message'] as Map<String, dynamic>)
          : null,
      assistantMessage: json['assistant_message'] != null
          ? Liya3dMessage.fromJson(json['assistant_message'] as Map<String, dynamic>)
          : null,
      suggestions: suggestions,
    );
  }
}

/// Response from /api/v1/external/sessions/{id}/history/ endpoint
class Liya3dSessionHistoryResponse {
  /// List of messages
  final List<Liya3dMessage> messages;

  /// Total message count
  final int total;

  /// Whether there are more messages
  final bool hasMore;

  const Liya3dSessionHistoryResponse({
    required this.messages,
    required this.total,
    required this.hasMore,
  });

  factory Liya3dSessionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List? ?? json['results'] as List? ?? [];
    return Liya3dSessionHistoryResponse(
      messages: messagesList
          .map((m) => Liya3dMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? json['count'] as int? ?? messagesList.length,
      hasMore: json['has_more'] as bool? ?? json['next'] != null,
    );
  }
}

/// Response from /api/v1/external/user/access/ endpoint
class Liya3dUserAccessResponse {
  /// Whether user has avatar access
  final bool hasAvatarAccess;

  /// Account type
  final Liya3dAccountType accountType;

  /// Whether user can use custom avatar
  final bool canUseCustomAvatar;

  /// Raw account type string
  final String accountTypeRaw;

  const Liya3dUserAccessResponse({
    required this.hasAvatarAccess,
    required this.accountType,
    required this.canUseCustomAvatar,
    required this.accountTypeRaw,
  });

  factory Liya3dUserAccessResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: {"status": "success", "data": {...}}
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final accountTypeStr = data['account_type'] as String? ?? 'standard';
    return Liya3dUserAccessResponse(
      hasAvatarAccess: data['has_avatar_access'] as bool? ?? false,
      accountType: Liya3dAccountTypeExtension.fromString(accountTypeStr),
      canUseCustomAvatar: data['can_use_custom_avatar'] as bool? ?? false,
      accountTypeRaw: accountTypeStr,
    );
  }
}

/// Response from /api/v1/external/avatar/model/ endpoint
class Liya3dAvatarModelResponse {
  /// Avatar model URL (GLB format)
  final String? modelUrl;

  /// Whether a custom model is available
  final bool hasCustomModel;

  /// Default model URL
  final String? defaultModelUrl;

  const Liya3dAvatarModelResponse({
    this.modelUrl,
    this.hasCustomModel = false,
    this.defaultModelUrl,
  });

  factory Liya3dAvatarModelResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: {"status": "success", "data": {...}}
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return Liya3dAvatarModelResponse(
      modelUrl: data['model_url'] as String? ?? data['avatar_model_url'] as String?,
      hasCustomModel: data['has_custom_model'] as bool? ?? false,
      defaultModelUrl: data['default_model_url'] as String?,
    );
  }

  /// Get the effective model URL (custom or default)
  String? get effectiveModelUrl => modelUrl ?? defaultModelUrl;
}

/// Response from /api/v1/external/files/upload/ endpoint
class Liya3dFileUploadResponse {
  /// Uploaded file ID
  final String fileId;

  /// File name
  final String fileName;

  /// File size
  final int fileSize;

  /// MIME type
  final String mimeType;

  const Liya3dFileUploadResponse({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  factory Liya3dFileUploadResponse.fromJson(Map<String, dynamic> json) {
    return Liya3dFileUploadResponse(
      fileId: json['file_id'] as String? ?? json['id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['name'] as String? ?? 'file',
      fileSize: json['file_size'] as int? ?? json['size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? json['content_type'] as String? ?? 'application/octet-stream',
    );
  }
}
