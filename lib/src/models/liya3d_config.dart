import 'package:flutter/material.dart';
import 'liya3d_enums.dart';

/// Main configuration for Liya 3D Avatar Widget
class Liya3dChatConfig {
  /// API Key for authentication (X-API-Key header)
  final String apiKey;

  /// Base URL for API calls (e.g., https://app-1-ai.liyalabs.com)
  final String baseUrl;

  /// Assistant ID (UUID)
  final String assistantId;

  /// Optional assistant display name
  final String? assistantName;

  /// Custom avatar model URL (GLB format)
  final String? avatarModelUrl;

  /// Theme configuration
  final Liya3dThemeConfig? theme;

  /// Feature flags configuration
  final Liya3dFeaturesConfig? features;

  /// Locale ('tr' or 'en')
  final String? locale;

  const Liya3dChatConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.assistantId,
    this.assistantName,
    this.avatarModelUrl,
    this.theme,
    this.features,
    this.locale,
  });

  Liya3dChatConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? assistantId,
    String? assistantName,
    String? avatarModelUrl,
    Liya3dThemeConfig? theme,
    Liya3dFeaturesConfig? features,
    String? locale,
  }) {
    return Liya3dChatConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      assistantId: assistantId ?? this.assistantId,
      assistantName: assistantName ?? this.assistantName,
      avatarModelUrl: avatarModelUrl ?? this.avatarModelUrl,
      theme: theme ?? this.theme,
      features: features ?? this.features,
      locale: locale ?? this.locale,
    );
  }
}

/// Theme configuration for the widget
class Liya3dThemeConfig {
  /// Primary color (default: #6366F1 - indigo-500)
  final Color? primaryColor;

  /// Secondary color (default: #8B5CF6 - violet-500)
  final Color? secondaryColor;

  /// Background color
  final Color? backgroundColor;

  /// Text color
  final Color? textColor;

  /// Font family
  final String? fontFamily;

  /// Border radius (default: 16)
  final double? borderRadius;

  /// Widget position on screen
  final Liya3dWidgetPosition? position;

  /// Z-index for web embedding
  final int? zIndex;

  const Liya3dThemeConfig({
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.textColor,
    this.fontFamily,
    this.borderRadius,
    this.position,
    this.zIndex,
  });

  Liya3dThemeConfig copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    String? fontFamily,
    double? borderRadius,
    Liya3dWidgetPosition? position,
    int? zIndex,
  }) {
    return Liya3dThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}

/// Feature flags configuration
class Liya3dFeaturesConfig {
  /// Enable voice input (default: true)
  final bool voice;

  /// Voice feature enabled for user's account type (STANDARD users: false)
  final bool voiceEnabled;

  /// Enable file upload (default: true)
  final bool fileUpload;

  /// Enable session history (default: true)
  final bool sessionHistory;

  /// Enable markdown rendering (default: true)
  final bool markdown;

  /// Show typing indicator (default: true)
  final bool typingIndicator;

  const Liya3dFeaturesConfig({
    this.voice = true,
    this.voiceEnabled = true,
    this.fileUpload = true,
    this.sessionHistory = true,
    this.markdown = true,
    this.typingIndicator = true,
  });

  Liya3dFeaturesConfig copyWith({
    bool? voice,
    bool? voiceEnabled,
    bool? fileUpload,
    bool? sessionHistory,
    bool? markdown,
    bool? typingIndicator,
  }) {
    return Liya3dFeaturesConfig(
      voice: voice ?? this.voice,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      fileUpload: fileUpload ?? this.fileUpload,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      markdown: markdown ?? this.markdown,
      typingIndicator: typingIndicator ?? this.typingIndicator,
    );
  }
}
