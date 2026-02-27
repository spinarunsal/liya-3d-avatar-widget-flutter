import 'package:flutter/material.dart';
import '../models/liya3d_config.dart';
import '../models/liya3d_enums.dart';
import '../models/liya3d_message.dart';
import '../services/liya3d_api_service.dart';
import '../services/liya3d_avatar_service.dart';
import '../services/liya3d_audio_service.dart';
import '../services/liya3d_storage_service.dart';
import '../controllers/liya3d_chat_controller.dart';
import '../controllers/liya3d_avatar_controller.dart';
import '../controllers/liya3d_voice_controller.dart';
import '../i18n/liya3d_translations.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_tts_utils.dart';
import 'liya3d_toggle_button.dart';
import 'liya3d_header.dart';
import 'liya3d_message_list.dart';
import 'liya3d_chat_input.dart';
import 'liya3d_avatar_webview.dart';
import 'liya3d_premium_overlay.dart';

/// Main Liya 3D Avatar Widget (Standard Mode)
/// Upper section: WebView avatar + liquid glass header
/// Lower section: MessageList + ChatInput + Branding
class Liya3dAvatarWidget extends StatefulWidget {
  /// Required configuration
  final Liya3dChatConfig config;

  /// Widget display mode
  final Liya3dWidgetMode mode;

  /// Widget position on screen
  final Liya3dWidgetPosition position;

  /// Theme configuration
  final Liya3dThemeConfig? theme;

  /// Horizontal offset from edge
  final double offsetX;

  /// Vertical offset from edge
  final double offsetY;

  /// Welcome message text
  final String? welcomeMessage;

  /// Welcome suggestion buttons
  final List<String>? welcomeSuggestions;

  /// Input placeholder text
  final String? placeholder;

  /// Show Liya branding
  final bool showBranding;

  /// Show voice input button
  final bool showVoice;

  /// Voice feature enabled (account type check)
  final bool voiceEnabled;

  /// Show file upload button
  final bool showFileUpload;

  /// Show avatar toggle button
  final bool showAvatarButton;

  /// Auto-speak assistant messages
  final bool autoSpeak;

  /// Animate toggle button
  final bool animateButton;

  /// Open widget on page start
  final bool viewOnPageStart;

  /// Enable close button
  final bool closeButtonEnabled;

  /// Locale ('tr' or 'en')
  final String? locale;

  /// Callback when widget opens
  final VoidCallback? onOpened;

  /// Callback when widget closes
  final VoidCallback? onClosed;

  /// Callback when message is sent
  final ValueChanged<String>? onMessageSent;

  /// Callback when message is received
  final ValueChanged<String>? onMessageReceived;

  /// Callback when avatar modal opens
  final VoidCallback? onAvatarOpened;

  /// Callback when avatar modal closes
  final VoidCallback? onAvatarClosed;

  const Liya3dAvatarWidget({
    super.key,
    required this.config,
    this.mode = Liya3dWidgetMode.standard,
    this.position = Liya3dWidgetPosition.bottomRight,
    this.theme,
    this.offsetX = 20,
    this.offsetY = 20,
    this.welcomeMessage,
    this.welcomeSuggestions,
    this.placeholder,
    this.showBranding = true,
    this.showVoice = true,
    this.voiceEnabled = true,
    this.showFileUpload = true,
    this.showAvatarButton = true,
    this.autoSpeak = true,
    this.animateButton = true,
    this.viewOnPageStart = false,
    this.closeButtonEnabled = true,
    this.locale,
    this.onOpened,
    this.onClosed,
    this.onMessageSent,
    this.onMessageReceived,
    this.onAvatarOpened,
    this.onAvatarClosed,
  });

  @override
  State<Liya3dAvatarWidget> createState() => _Liya3dAvatarWidgetState();
}

class _Liya3dAvatarWidgetState extends State<Liya3dAvatarWidget>
    with SingleTickerProviderStateMixin {
  // Services
  late Liya3dApiService _apiService;
  late Liya3dAvatarService _avatarService;
  late Liya3dAudioService _audioService;
  late Liya3dStorageService _storageService;

  // Controllers
  late Liya3dChatController _chatController;
  late Liya3dAvatarController _avatarController;
  late Liya3dVoiceController _voiceController;

  // State
  bool _isOpen = false;
  bool _isInitialized = false;
  bool _hasAccess = true;
  String _locale = 'tr';
  Liya3dTranslations _translations = Liya3dTranslations.tr;

  // Animation
  late AnimationController _panelAnimationController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? widget.config.locale ?? 'tr';
    _translations = Liya3dTranslations.byLocale(_locale);

    _initServices();
    _initControllers();
    _initAnimations();

    if (widget.viewOnPageStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openWidget();
      });
    }
  }

  void _initServices() {
    _apiService = Liya3dApiService(
      baseUrl: widget.config.baseUrl,
      apiKey: widget.config.apiKey,
      assistantId: widget.config.assistantId,
    );

    _audioService = Liya3dAudioService();

    _avatarService = Liya3dAvatarService(
      apiService: _apiService,
      customModelUrl: widget.config.avatarModelUrl,
    );

    _storageService = Liya3dStorageService(
      assistantId: widget.config.assistantId,
    );
  }

  void _initControllers() {
    _chatController = Liya3dChatController(
      apiService: _apiService,
      storageService: _storageService,
    );

    _avatarController = Liya3dAvatarController(
      avatarService: _avatarService,
      audioService: _audioService,
    );

    _voiceController = Liya3dVoiceController();

    // Setup callbacks
    _chatController.onAssistantMessage = _onAssistantMessage;
    _chatController.addListener(_onChatStateChanged);
    _avatarController.addListener(_onAvatarStateChanged);
    _voiceController.addListener(_onVoiceStateChanged);

    _voiceController.onComplete = _onVoiceComplete;
  }

  void _initAnimations() {
    _panelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Initialize storage
    await _storageService.init();

    // Initialize chat controller
    await _chatController.init();

    // Check access
    _hasAccess = await _avatarService.checkAccess();

    // Load history if session exists
    if (_chatController.sessionId != null) {
      await _chatController.loadHistory();
    }

    // Add welcome message if no messages
    if (!_chatController.hasMessages) {
      _chatController.addWelcomeMessage(
        widget.welcomeMessage ?? _translations.welcomeMessage,
        suggestions:
            widget.welcomeSuggestions ?? _translations.welcomeSuggestions,
      );
    }

    // Initialize voice
    await _voiceController.init(locale: _locale);

    _isInitialized = true;
    if (mounted) setState(() {});
  }

  void _onChatStateChanged() {
    if (mounted) setState(() {});
  }

  void _onAvatarStateChanged() {
    if (mounted) setState(() {});
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  void _onAssistantMessage(Liya3dMessage message) {
    widget.onMessageReceived?.call(message.content);

    // Auto-speak — strip markdown/URLs for clean TTS
    if (widget.autoSpeak && message.content.isNotEmpty) {
      _avatarController.speak(Liya3dTtsUtils.stripForTTS(message.content));
    }
  }

  void _onVoiceComplete(String transcript) {
    if (transcript.isNotEmpty) {
      _handleSendMessage(transcript);
    }
  }

  void _openWidget() {
    if (_isOpen) return;

    setState(() {
      _isOpen = true;
    });

    _panelAnimationController.forward();
    _initialize();

    widget.onOpened?.call();
  }

  void _closeWidget() {
    if (!_isOpen) return;

    _panelAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });

    widget.onClosed?.call();
  }

  void _toggleWidget() {
    if (_isOpen) {
      _closeWidget();
    } else {
      _openWidget();
    }
  }

  void _handleSendMessage(String message) {
    widget.onMessageSent?.call(message);
    _chatController.sendMessage(message);
  }

  void _handleSuggestionTap(String suggestion) {
    _handleSendMessage(suggestion);
  }

  void _handleMicPressed() {
    if (_voiceController.isListening) {
      _voiceController.stopListening();
    } else {
      _voiceController.startListening();
    }
  }

  void _handleReplay() {
    final lastMessage = _chatController.lastAssistantMessage;
    if (lastMessage != null && lastMessage.content.isNotEmpty) {
      _avatarController.speak(Liya3dTtsUtils.stripForTTS(lastMessage.content));
    }
  }

  void _handleStop() {
    _avatarController.stopSpeaking();
  }

  void _handleLanguageToggle() {
    setState(() {
      _locale = _locale == 'tr' ? 'en' : 'tr';
      _translations = Liya3dTranslations.byLocale(_locale);
      _voiceController.setLocale(_locale);
    });
    _storageService.saveLocale(_locale);
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _chatController.dispose();
    _avatarController.dispose();
    _voiceController.dispose();
    _audioService.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat panel
        if (_isOpen) _buildChatPanel(),

        // Toggle button
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildToggleButton() {
    double? left, right, top, bottom;

    switch (widget.position) {
      case Liya3dWidgetPosition.bottomRight:
        right = widget.offsetX;
        bottom = widget.offsetY;
        break;
      case Liya3dWidgetPosition.bottomLeft:
        left = widget.offsetX;
        bottom = widget.offsetY;
        break;
      case Liya3dWidgetPosition.topRight:
        right = widget.offsetX;
        top = widget.offsetY;
        break;
      case Liya3dWidgetPosition.topLeft:
        left = widget.offsetX;
        top = widget.offsetY;
        break;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Liya3dToggleButton(
        isOpen: _isOpen,
        onPressed: _toggleWidget,
        animate: widget.animateButton,
      ),
    );
  }

  Widget _buildChatPanel() {
    final screenSize = MediaQuery.of(context).size;
    final panelWidth = screenSize.width > 500 ? 400.0 : screenSize.width - 40;
    final panelHeight = screenSize.height * 0.7;

    double? left, right, top, bottom;

    switch (widget.position) {
      case Liya3dWidgetPosition.bottomRight:
        right = widget.offsetX;
        bottom = widget.offsetY + 70;
        break;
      case Liya3dWidgetPosition.bottomLeft:
        left = widget.offsetX;
        bottom = widget.offsetY + 70;
        break;
      case Liya3dWidgetPosition.topRight:
        right = widget.offsetX;
        top = widget.offsetY + 70;
        break;
      case Liya3dWidgetPosition.topLeft:
        left = widget.offsetX;
        top = widget.offsetY + 70;
        break;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _panelAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_panelAnimation.value * 0.2),
            alignment: _getScaleAlignment(),
            child: Opacity(
              opacity: _panelAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          width: panelWidth,
          height: panelHeight,
          decoration: BoxDecoration(
            color: Liya3dColors.bgDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _hasAccess ? _buildChatContent() : _buildPremiumOverlay(),
        ),
      ),
    );
  }

  Alignment _getScaleAlignment() {
    switch (widget.position) {
      case Liya3dWidgetPosition.bottomRight:
        return Alignment.bottomRight;
      case Liya3dWidgetPosition.bottomLeft:
        return Alignment.bottomLeft;
      case Liya3dWidgetPosition.topRight:
        return Alignment.topRight;
      case Liya3dWidgetPosition.topLeft:
        return Alignment.topLeft;
    }
  }

  Widget _buildChatContent() {
    return Column(
      children: [
        // Avatar section (upper half)
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              // WebView avatar
              Liya3dAvatarWebView(
                controller: _avatarController,
              ),

              // Header overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Liya3dHeader(
                  assistantName: widget.config.assistantName,
                  status: _avatarController.status,
                  canReplay: _chatController.canReplay,
                  isSpeaking: _avatarController.isSpeaking,
                  locale: _locale,
                  translations: _translations,
                  onClose: _closeWidget,
                  onReplay: _handleReplay,
                  onStop: _handleStop,
                  onLanguageToggle: _handleLanguageToggle,
                  closeButtonEnabled: widget.closeButtonEnabled,
                ),
              ),
            ],
          ),
        ),

        // Chat section (lower half)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Liya3dColors.primary.withValues(alpha: 0.1),
                  Liya3dColors.bgDark,
                ],
              ),
            ),
            child: Column(
              children: [
                // Message list
                Expanded(
                  child: Liya3dMessageList(
                    messages: _chatController.messages,
                    onSuggestionTap: _handleSuggestionTap,
                  ),
                ),

                // Chat input
                Liya3dChatInput(
                  onSubmit: _handleSendMessage,
                  onMicPressed: _handleMicPressed,
                  showVoice: widget.showVoice,
                  voiceEnabled: widget.voiceEnabled,
                  isRecording: _voiceController.isListening,
                  showFileUpload: widget.showFileUpload,
                  isDisabled: _chatController.isLoading,
                  placeholder: widget.placeholder,
                  translations: _translations,
                  transcript: _voiceController.transcript,
                ),

                // Branding
                if (widget.showBranding) _buildBranding(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_translations.poweredBy} ',
            style: TextStyle(
              color: Liya3dColors.textMuted,
              fontSize: 11,
            ),
          ),
          Text(
            'Liya',
            style: TextStyle(
              color: Liya3dColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOverlay() {
    return Liya3dPremiumOverlay(
      translations: _translations,
      requiresPremiumPlus: false,
      onClose: _closeWidget,
    );
  }
}
