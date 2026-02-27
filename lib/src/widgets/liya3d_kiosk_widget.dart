import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/liya3d_config.dart';

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
import 'liya3d_avatar_webview.dart';

/// Kiosk mode widget (matches Vue.js AvatarModal.vue layout)
/// Layout: Header → Avatar → Message Box → Suggestions → Mic Button
class Liya3dKioskWidget extends StatefulWidget {
  /// Required configuration
  final Liya3dChatConfig config;

  /// Whether this is modal kiosk (overlay) or full kiosk
  final bool isModal;

  /// Locale ('tr' or 'en')
  final String? locale;

  /// Welcome message
  final String? welcomeMessage;

  /// Welcome suggestions
  final List<String>? welcomeSuggestions;

  /// Callback when widget closes
  final VoidCallback? onClose;

  /// Callback when message is sent
  final ValueChanged<String>? onMessageSent;

  /// Callback when message is received
  final ValueChanged<String>? onMessageReceived;

  /// Callback when avatar is loaded
  final VoidCallback? onAvatarLoaded;

  const Liya3dKioskWidget({
    super.key,
    required this.config,
    this.isModal = false,
    this.locale,
    this.welcomeMessage,
    this.welcomeSuggestions,
    this.onClose,
    this.onMessageSent,
    this.onMessageReceived,
    this.onAvatarLoaded,
  });

  @override
  State<Liya3dKioskWidget> createState() => _Liya3dKioskWidgetState();
}

class _Liya3dKioskWidgetState extends State<Liya3dKioskWidget> {
  // Services
  late Liya3dApiService _apiService;
  late Liya3dAvatarService _avatarService;
  late Liya3dAudioService _audioService;
  late Liya3dStorageService _storageService;

  // Controllers
  late Liya3dChatController _chatController;
  late Liya3dAvatarController _avatarController;
  late Liya3dVoiceController _voiceController;

  // Scroll controller for chat
  final ScrollController _scrollController = ScrollController();

  // State

  bool _welcomeSpoken = false;
  String _locale = 'tr';
  Liya3dTranslations _translations = Liya3dTranslations.tr;

  // Chat messages for bubble display
  final List<_ChatMessage> _chatMessages = [];

  // Typewriter effect state
  String _typewriterText = '';
  String _fullResponseText = '';
  Timer? _typewriterTimer;
  int _typewriterIndex = 0;

  // Pending typewriter data (wait for audio to start)
  int? _pendingMessageIndex;
  int? _pendingMsPerChar;
  bool _pendingIsWelcome = false;

  // Current user input
  String _userInput = '';

  // Prevent duplicate message sends
  String? _lastSentMessage;

  // Processing state for button disable
  bool _isProcessing = false;

  // Auto-hide suggestions timer
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? widget.config.locale ?? 'tr';
    _translations = Liya3dTranslations.byLocale(_locale);

    _initServices();
    _initControllers();
    _initialize();
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
    _chatController.addListener(_onStateChanged);
    _avatarController.addListener(_onStateChanged);
    _voiceController.addListener(_onStateChanged);

    _voiceController.onComplete = _onVoiceComplete;
    _voiceController.onTranscriptUpdate = (transcript) {
      setState(() {
        _userInput = transcript;
      });
    };

    // Avatar loaded callback - speak welcome message
    _avatarController.onModelLoaded = _onAvatarLoaded;

    // Start typewriter when audio actually starts playing
    _avatarController.onSpeakingStarted = _onSpeakingStarted;
  }

  Future<void> _initialize() async {
    await _storageService.init();
    await _chatController.init();
    await _voiceController.init(locale: _locale);

    if (mounted) setState(() {});
  }

  void _onAvatarLoaded() {
    if (!mounted) return;

    widget.onAvatarLoaded?.call();

    if (!_welcomeSpoken && mounted) {
      _welcomeSpoken = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_avatarController.isSpeaking) {
          final welcomeMsg =
              widget.welcomeMessage ?? _translations.welcomeMessage;
          _speakWithTypewriter(welcomeMsg, isWelcome: true);
        }
      });
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  /// Called when audio actually starts playing - start typewriter here
  void _onSpeakingStarted() {
    if (!mounted || _pendingMessageIndex == null || _pendingMsPerChar == null) {
      return;
    }

    final messageIndex = _pendingMessageIndex!;
    final msPerChar = _pendingMsPerChar!;
    final text = _fullResponseText;
    final isWelcome = _pendingIsWelcome;

    // Clear pending state
    _pendingMessageIndex = null;
    _pendingMsPerChar = null;
    _pendingIsWelcome = false;

    // Start typewriter effect NOW (audio has started)
    _typewriterTimer = Timer.periodic(
      Duration(milliseconds: msPerChar.clamp(20, 100)),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_typewriterIndex < text.length) {
          setState(() {
            _typewriterIndex++;
            _typewriterText = text.substring(0, _typewriterIndex);
            if (messageIndex < _chatMessages.length) {
              _chatMessages[messageIndex] = _ChatMessage(
                role: 'assistant',
                content: _typewriterText,
                isTyping: _typewriterIndex < text.length,
              );
            }
          });
          _scrollToBottom();
        } else {
          timer.cancel();
          final finalSuggestions = isWelcome
              ? (widget.welcomeSuggestions ?? _translations.welcomeSuggestions)
              : (_chatController.suggestions.isNotEmpty
                  ? _chatController.suggestions
                  : null);
          setState(() {
            _isProcessing = false;
            if (messageIndex < _chatMessages.length) {
              _chatMessages[messageIndex] = _ChatMessage(
                role: 'assistant',
                content: text,
                isTyping: false,
                suggestions: finalSuggestions,
              );
            }
          });
          if (finalSuggestions != null) _startSuggestionAutoHide();
        }
      },
    );
  }

  void _onAssistantMessage(Liya3dMessage message) {
    widget.onMessageReceived?.call(message.content);

    // Speak with typewriter effect — strip markdown/URLs for clean TTS
    if (message.content.isNotEmpty) {
      _speakWithTypewriter(message.content);
    }
  }

  /// Speak text and show typewriter effect synchronized with speech
  Future<void> _speakWithTypewriter(String text,
      {bool isWelcome = false}) async {
    _typewriterTimer?.cancel();

    setState(() {
      _fullResponseText = text;
      _typewriterText = '';
      _typewriterIndex = 0;
      _isProcessing = true;
    });

    // Add assistant message placeholder
    final messageIndex = _chatMessages.length;
    _chatMessages.add(_ChatMessage(
      role: 'assistant',
      content: '',
      isTyping: true,
    ));

    try {
      // Strip markdown/URLs for clean TTS, keep original text for display
      final ttsText = Liya3dTtsUtils.stripForTTS(text);
      final response = await _avatarService.generateSpeech(ttsText);

      if (response.success && response.data != null && mounted) {
        final speechData = response.data!;

        if (!speechData.hasAudio || speechData.duration <= 0) {
          _showTextWithTypewriter(text, messageIndex, isWelcome);
          return;
        }

        // Calculate typing speed based on audio duration
        final audioDuration = speechData.duration;
        final charCount = text.length;
        final msPerChar = (audioDuration * 1000 / charCount).round();

        // Store pending typewriter data - will start when audio actually begins
        _pendingMessageIndex = messageIndex;
        _pendingMsPerChar = msPerChar;
        _pendingIsWelcome = isWelcome;

        // Start speaking - typewriter will start via onSpeakingStarted callback
        _avatarController.speakWithData(speechData);
      } else {
        // Fallback: show text immediately without speech
        final suggestions = isWelcome
            ? (widget.welcomeSuggestions ?? _translations.welcomeSuggestions)
            : (_chatController.suggestions.isNotEmpty
                ? _chatController.suggestions
                : null);
        setState(() {
          _isProcessing = false;
          if (messageIndex < _chatMessages.length) {
            _chatMessages[messageIndex] = _ChatMessage(
              role: 'assistant',
              content: text,
              isTyping: false,
              suggestions: suggestions,
            );
          }
        });
        if (suggestions != null) _startSuggestionAutoHide();
      }
    } catch (_) {
      _showTextWithTypewriter(text, messageIndex, isWelcome);
    }

    _scrollToBottom();
  }

  /// Fallback: show text with typewriter effect without audio
  void _showTextWithTypewriter(String text, int messageIndex, bool isWelcome) {
    final suggestions = isWelcome
        ? (widget.welcomeSuggestions ?? _translations.welcomeSuggestions)
        : (_chatController.suggestions.isNotEmpty
            ? _chatController.suggestions
            : null);

    // Simple typewriter without audio - 30ms per character
    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_typewriterIndex < text.length) {
          setState(() {
            _typewriterIndex++;
            _typewriterText = text.substring(0, _typewriterIndex);
            if (messageIndex < _chatMessages.length) {
              _chatMessages[messageIndex] = _ChatMessage(
                role: 'assistant',
                content: _typewriterText,
                isTyping: _typewriterIndex < text.length,
              );
            }
          });
          _scrollToBottom();
        } else {
          timer.cancel();
          setState(() {
            _isProcessing = false;
            if (messageIndex < _chatMessages.length) {
              _chatMessages[messageIndex] = _ChatMessage(
                role: 'assistant',
                content: text,
                isTyping: false,
                suggestions: suggestions,
              );
            }
          });
          if (suggestions != null) _startSuggestionAutoHide();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onVoiceComplete(String transcript) {
    if (transcript.isEmpty || transcript == _lastSentMessage) return;

    _lastSentMessage = transcript;
    widget.onMessageSent?.call(transcript);

    // Add user message to chat and clear old suggestions
    setState(() {
      _clearLastSuggestions();
      _chatMessages.add(_ChatMessage(
        role: 'user',
        content: transcript,
      ));
      _userInput = '';
    });

    _scrollToBottom();
    _chatController.sendMessage(transcript);
  }

  void _handleMicPressed() {
    if (_voiceController.isListening) {
      _voiceController.stopListening();
    } else {
      setState(() {
        _userInput = '';
        _lastSentMessage = null; // Reset duplicate check
      });
      _avatarController.setListening(true);
      _voiceController.startListening();
    }
  }

  void _handleSuggestionTap(String suggestion) {
    widget.onMessageSent?.call(suggestion);

    // Add user message to chat and clear old suggestions
    setState(() {
      _clearLastSuggestions();
      _chatMessages.add(_ChatMessage(
        role: 'user',
        content: suggestion,
      ));
    });

    _scrollToBottom();
    _chatController.sendMessage(suggestion);
  }

  /// Clear suggestions from all previous assistant messages
  void _clearLastSuggestions() {
    _suggestionTimer?.cancel();
    for (int i = 0; i < _chatMessages.length; i++) {
      final msg = _chatMessages[i];
      if (msg.role == 'assistant' && msg.suggestions != null) {
        _chatMessages[i] = _ChatMessage(
          role: msg.role,
          content: msg.content,
          isTyping: msg.isTyping,
          suggestions: null,
        );
      }
    }
  }

  /// Start auto-hide timer for suggestions
  void _startSuggestionAutoHide() {
    _suggestionTimer?.cancel();
    _suggestionTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _clearLastSuggestions();
        });
      }
    });
  }

  String _getHintText() {
    if (_voiceController.isListening) return _translations.listening;
    if (_chatController.isLoading || _isProcessing) {
      return _translations.preparingMessages[
          DateTime.now().second % _translations.preparingMessages.length];
    }
    return _translations.speakToMic;
  }

  /// Toggle locale between TR and EN
  void _toggleLocale() {
    setState(() {
      _locale = _locale == 'tr' ? 'en' : 'tr';
      _translations = Liya3dTranslations.byLocale(_locale);
    });
  }

  /// Cancel current action (stop speaking, stop loading)
  void _cancelCurrentAction() {
    if (_voiceController.isListening) {
      _voiceController.stopListening();
    }

    // Stop avatar speaking
    _avatarController.stopSpeaking();

    // Cancel typewriter effect
    _typewriterTimer?.cancel();
    _typewriterTimer = null;

    // Clear pending typewriter state
    _pendingMessageIndex = null;
    _pendingMsPerChar = null;
    _pendingIsWelcome = false;

    // Reset processing state
    setState(() {
      _isProcessing = false;
      _userInput = '';
    });
  }

  /// Reload/refresh the conversation
  void _reloadConversation() {
    // Cancel any current action first
    _cancelCurrentAction();

    // Clear chat messages
    setState(() {
      _chatMessages.clear();
      _welcomeSpoken = false;
    });

    // Re-speak welcome message after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_avatarController.isSpeaking) {
        final welcomeMsg =
            widget.welcomeMessage ?? _translations.welcomeMessage;
        _speakWithTypewriter(welcomeMsg, isWelcome: true);
      }
    });
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _typewriterTimer?.cancel();
    _scrollController.dispose();
    _chatController.dispose();
    _avatarController.dispose();
    _voiceController.dispose();
    _audioService.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = _avatarController.isModelLoaded;
    final assistantName = widget.config.assistantName ?? 'AI Assistant';

    return Stack(
      children: [
        // Main UI (builds underneath, hidden during loading)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isLoaded ? 1.0 : 0.0,
          child: _buildMainUI(),
        ),

        // Full screen loading overlay
        if (!isLoaded) _buildFullScreenLoader(assistantName),
      ],
    );
  }

  Widget _buildFullScreenLoader(String assistantName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0a0a14),
            Color(0xFF101020),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinning gradient ring
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 24),
            // Assistant name
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFFA78BFA),
                ],
              ).createShader(bounds),
              child: Text(
                assistantName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$assistantName asistan yükleniyor...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0a0a14),
            Color(0xFF101020),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final isTablet = constraints.maxWidth > 600;
            final avatarHeight = screenHeight * (isTablet ? 0.38 : 0.33);

            return Column(
              children: [
                _buildGlassHeader(),
                SizedBox(
                  height: avatarHeight,
                  child: Stack(
                    children: [
                      Liya3dAvatarWebView(
                        controller: _avatarController,
                        showLoading: false,
                        assistantName:
                            widget.config.assistantName ?? 'AI Assistant',
                      ),
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _buildAvatarActionButtons(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildGlassChatArea(),
                ),
                _buildGlassVoiceControl(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Liquid Glass Header
  Widget _buildGlassHeader() {
    final isSpeaking = _avatarController.isSpeaking;
    final isListening = _voiceController.isListening;
    final assistantName = widget.config.assistantName ?? 'AI Assistant';

    Color statusColor = Liya3dColors.statusIdle;
    String statusText = '';
    if (isSpeaking) {
      statusColor = Liya3dColors.statusSpeaking;
      statusText = _translations.speaking;
    } else if (isListening) {
      statusColor = Liya3dColors.statusListening;
      statusText = _translations.listening;
    } else if (_chatController.isLoading || _isProcessing) {
      statusColor = Liya3dColors.statusPreparing;
      // Fun waiting messages - rotate based on time
      final messages = _translations.preparingMessages;
      statusText = messages[DateTime.now().second % messages.length];
    } else {
      statusColor = Liya3dColors.statusIdle;
      statusText = _translations.ready;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status indicator (liquid glass pill)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusDot(
                      color: statusColor,
                      isPulsing: isSpeaking ||
                          isListening ||
                          _chatController.isLoading,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assistantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (statusText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Close button only in header
          if (widget.onClose != null)
            _buildGlassIconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
              onTap: widget.onClose,
              isDisabled: false,
            ),
        ],
      ),
    );
  }

  /// Build action buttons (language + reload/cancel) for avatar area
  Widget _buildAvatarActionButtons() {
    final isActionInProgress = _isProcessing ||
        _avatarController.isSpeaking ||
        _chatController.isLoading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language toggle button (TR/EN)
              GestureDetector(
                onTap: isActionInProgress ? null : _toggleLocale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActionInProgress ? 0.4 : 1.0,
                    child: Text(
                      _locale.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white.withValues(alpha: 0.2),
              ),

              // Reload/Cancel button
              GestureDetector(
                onTap: isActionInProgress
                    ? _cancelCurrentAction
                    : _reloadConversation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActionInProgress
                        ? const Color(0xFFef4444).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isActionInProgress ? Icons.close : Icons.refresh,
                    color: isActionInProgress
                        ? const Color(0xFFef4444)
                        : Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a liquid glass icon button
  Widget _buildGlassIconButton({
    required Widget icon,
    VoidCallback? onTap,
    bool isDisabled = false,
    bool isCancel = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCancel
                  ? const Color(0xFFef4444).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCancel
                    ? const Color(0xFFef4444).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isDisabled ? 0.4 : 1.0,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid Glass Chat Area
  Widget _buildGlassChatArea() {
    // Always show chat area with fixed height
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Chat messages (scrollable) or empty state
                Expanded(
                  child: _chatMessages.isEmpty &&
                          _userInput.isEmpty &&
                          !_chatController.isLoading
                      ? Center(
                          child: Text(
                            _translations.speakToMic,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _chatMessages[index];
                            final isLast = index == _chatMessages.length - 1;
                            return _buildGlassChatBubble(message,
                                isLast: isLast);
                          },
                        ),
                ),

                // User input display (when listening)
                if (_userInput.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366f1).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366f1)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _userInput,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading indicator
                if (_chatController.isLoading && _userInput.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildThinkingDots(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Liquid Glass Chat Bubble
  Widget _buildGlassChatBubble(_ChatMessage message, {bool isLast = false}) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF6366f1).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMarkdownText(
                  message.content,
                  isUser: isUser,
                ),
                // Typing indicator
                if (message.isTyping)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 8,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Suggestions (only for last assistant message)
          if (!isUser &&
              isLast &&
              message.suggestions != null &&
              message.suggestions!.isNotEmpty &&
              !message.isTyping)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions!.take(3).map((suggestion) {
                  return GestureDetector(
                    onTap: () => _handleSuggestionTap(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6366f1).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          color: Color(0xFF8b9cf6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Liquid Glass Voice Control
  Widget _buildGlassVoiceControl() {
    final isListening = _voiceController.isListening;
    final isDisabled =
        _chatController.isLoading || _avatarController.isSpeaking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hint text (liquid glass pill)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getHintText(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Mic Button (liquid glass with gradient)
          GestureDetector(
            onTap: isDisabled ? null : _handleMicPressed,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isListening
                        ? const LinearGradient(
                            colors: [Color(0xFFef4444), Color(0xFFf97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isListening
                            ? const Color(0xFFef4444).withValues(alpha: 0.4)
                            : const Color(0xFF6366f1).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build text with simple markdown support (bold **text**)
  Widget _buildMarkdownText(String text, {required bool isUser}) {
    final textColor =
        isUser ? Colors.white : Colors.white.withValues(alpha: 0.9);
    final boldStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.bold,
    );
    final normalStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      height: 1.4,
    );

    // Parse **bold** markdown
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
            text: text.substring(lastEnd, match.start), style: normalStyle));
      }
      // Add bold text
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: normalStyle));
    }

    // If no markdown found, return simple text
    if (spans.isEmpty) {
      return Text(text, style: normalStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildThinkingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + (index * 160)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    Liya3dColors.primary.withValues(alpha: 0.5 + (value * 0.5)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Internal chat message model
class _ChatMessage {
  final String role;
  final String content;
  final bool isTyping;
  final List<String>? suggestions;

  _ChatMessage({
    required this.role,
    required this.content,
    this.isTyping = false,
    this.suggestions,
  });
}

class _StatusDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _StatusDot({required this.color, required this.isPulsing});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          transform:
              Matrix4.diagonal3Values(_animation.value, _animation.value, 1.0),
        );
      },
    );
  }
}
