/// File attachment model for chat messages
class Liya3dFileAttachment {
  /// Unique file ID from server
  final String id;

  /// Original file name
  final String name;

  /// File size in bytes
  final int size;

  /// MIME type
  final String mimeType;

  /// File URL (if available)
  final String? url;

  /// Upload timestamp
  final DateTime? createdAt;

  const Liya3dFileAttachment({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    this.url,
    this.createdAt,
  });

  factory Liya3dFileAttachment.fromJson(Map<String, dynamic> json) {
    return Liya3dFileAttachment(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['filename'] as String? ?? 'file',
      size: json['size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? json['content_type'] as String? ?? 'application/octet-stream',
      url: json['url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'mime_type': mimeType,
      if (url != null) 'url': url,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Human-readable file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file is an image
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  /// Check if file is a PDF
  bool get isPdf {
    return mimeType == 'application/pdf';
  }
}
