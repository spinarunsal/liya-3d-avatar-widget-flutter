import 'liya3d_enums.dart';
import 'liya3d_file_attachment.dart';

/// Chat message model
class Liya3dMessage {
  /// Unique message ID
  final String id;

  /// Message content (text)
  final String content;

  /// Sender role (user or assistant)
  final Liya3dMessageRole role;

  /// Message creation timestamp
  final DateTime createdAt;

  /// Response time in seconds (for assistant messages)
  final double? responseTime;

  /// File attachments
  final List<Liya3dFileAttachment>? attachments;

  /// Suggestion buttons (for assistant messages)
  final List<String>? suggestions;

  /// Whether this is a temporary/optimistic message
  final bool isTemporary;

  /// Whether this message is currently being typed (typing indicator)
  final bool isTyping;

  const Liya3dMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.responseTime,
    this.attachments,
    this.suggestions,
    this.isTemporary = false,
    this.isTyping = false,
  });

  factory Liya3dMessage.fromJson(Map<String, dynamic> json) {
    return Liya3dMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      role: json['role'] == 'user' ? Liya3dMessageRole.user : Liya3dMessageRole.assistant,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      responseTime: json['response_time'] != null
          ? (json['response_time'] as num).toDouble()
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => Liya3dFileAttachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role == Liya3dMessageRole.user ? 'user' : 'assistant',
      'created_at': createdAt.toIso8601String(),
      if (responseTime != null) 'response_time': responseTime,
      if (attachments != null) 'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (suggestions != null) 'suggestions': suggestions,
    };
  }

  Liya3dMessage copyWith({
    String? id,
    String? content,
    Liya3dMessageRole? role,
    DateTime? createdAt,
    double? responseTime,
    List<Liya3dFileAttachment>? attachments,
    List<String>? suggestions,
    bool? isTemporary,
    bool? isTyping,
  }) {
    return Liya3dMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      responseTime: responseTime ?? this.responseTime,
      attachments: attachments ?? this.attachments,
      suggestions: suggestions ?? this.suggestions,
      isTemporary: isTemporary ?? this.isTemporary,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Create a temporary user message (optimistic update)
  factory Liya3dMessage.temporaryUser(String content, {List<Liya3dFileAttachment>? attachments}) {
    return Liya3dMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      role: Liya3dMessageRole.user,
      createdAt: DateTime.now(),
      attachments: attachments,
      isTemporary: true,
    );
  }

  /// Create a typing indicator message
  factory Liya3dMessage.typingIndicator() {
    return Liya3dMessage(
      id: 'typing_indicator',
      content: '',
      role: Liya3dMessageRole.assistant,
      createdAt: DateTime.now(),
      isTyping: true,
    );
  }
}
