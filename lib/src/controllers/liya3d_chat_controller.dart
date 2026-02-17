import 'package:flutter/foundation.dart';
import '../models/liya3d_message.dart';
import '../models/liya3d_enums.dart';
import '../models/liya3d_api_response.dart';
import '../models/liya3d_file_attachment.dart';
import '../services/liya3d_api_service.dart';
import '../services/liya3d_storage_service.dart';

/// Chat state controller
/// Manages messages, loading state, and API interactions
class Liya3dChatController extends ChangeNotifier {
  final Liya3dApiService _apiService;
  final Liya3dStorageService _storageService;

  /// List of chat messages
  final List<Liya3dMessage> _messages = [];
  List<Liya3dMessage> get messages => List.unmodifiable(_messages);

  /// Current session ID
  String? _sessionId;
  String? get sessionId => _sessionId;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _error;
  String? get error => _error;

  /// Whether history has been loaded
  bool _historyLoaded = false;
  bool get historyLoaded => _historyLoaded;

  /// Last assistant message (for replay)
  Liya3dMessage? _lastAssistantMessage;
  Liya3dMessage? get lastAssistantMessage => _lastAssistantMessage;

  /// Current suggestions
  List<String> _suggestions = [];
  List<String> get suggestions => List.unmodifiable(_suggestions);

  /// Callback when assistant message is received (for auto-speak)
  void Function(Liya3dMessage message)? onAssistantMessage;

  Liya3dChatController({
    required Liya3dApiService apiService,
    required Liya3dStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  /// Initialize controller - load session from storage
  Future<void> init() async {
    _sessionId = await _storageService.getSessionId();
  }

  /// Add welcome message
  void addWelcomeMessage(String message, {List<String>? suggestions}) {
    if (_messages.isNotEmpty) return;

    final welcomeMsg = Liya3dMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      role: Liya3dMessageRole.assistant,
      createdAt: DateTime.now(),
      suggestions: suggestions,
    );

    _messages.add(welcomeMsg);
    _lastAssistantMessage = welcomeMsg;
    if (suggestions != null) {
      _suggestions = suggestions;
    }
    notifyListeners();
  }

  /// Update welcome message (if it's the only message)
  void updateWelcomeMessage(String message, {List<String>? suggestions}) {
    if (_messages.length == 1 && _messages.first.id.startsWith('welcome_')) {
      _messages[0] = _messages[0].copyWith(
        content: message,
        suggestions: suggestions,
      );
      if (suggestions != null) {
        _suggestions = suggestions;
      }
      notifyListeners();
    }
  }

  /// Load session history
  Future<void> loadHistory({int limit = 50}) async {
    if (_sessionId == null || _historyLoaded) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _apiService.getSessionHistory(_sessionId!, limit: limit);

    _isLoading = false;

    if (response.success && response.data != null) {
      _messages.clear();
      _messages.addAll(response.data!.messages);
      _historyLoaded = true;

      // Find last assistant message
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].role == Liya3dMessageRole.assistant) {
          _lastAssistantMessage = _messages[i];
          break;
        }
      }
    } else {
      _error = response.error;
    }

    notifyListeners();
  }

  /// Send a message
  Future<Liya3dSendMessageResponse?> sendMessage(
    String content, {
    List<Liya3dFileAttachment>? attachments,
    List<String>? fileIds,
  }) async {
    if (content.trim().isEmpty && (fileIds == null || fileIds.isEmpty)) {
      return null;
    }

    // Clear suggestions
    _suggestions = [];

    // Add temporary user message (optimistic update)
    final tempUserMessage = Liya3dMessage.temporaryUser(
      content,
      attachments: attachments,
    );
    _messages.add(tempUserMessage);

    // Add typing indicator
    final typingIndicator = Liya3dMessage.typingIndicator();
    _messages.add(typingIndicator);

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _apiService.sendMessage(
      content,
      sessionId: _sessionId,
      fileIds: fileIds,
    );

    // Remove typing indicator
    _messages.removeWhere((m) => m.isTyping);

    _isLoading = false;

    if (response.success && response.data != null) {
      final data = response.data!;

      // Update session ID
      if (data.sessionId.isNotEmpty) {
        _sessionId = data.sessionId;
        await _storageService.saveSessionId(_sessionId!);
      }

      // Replace temp user message with real one
      final tempIndex = _messages.indexWhere((m) => m.id == tempUserMessage.id);
      if (tempIndex >= 0 && data.userMessage != null) {
        _messages[tempIndex] = data.userMessage!;
      } else if (tempIndex >= 0) {
        // Keep temp message but mark as not temporary
        _messages[tempIndex] = tempUserMessage.copyWith(isTemporary: false);
      }

      // Add assistant message (check both assistant_message and response fields like Vue.js widget)
      Liya3dMessage? assistantMsg = data.assistantMessage;
      
      // If no assistant_message but response exists, create message from response (Vue.js fallback)
      if (assistantMsg == null && data.response != null && data.response!.isNotEmpty) {
        assistantMsg = Liya3dMessage(
          id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
          content: data.response!,
          role: Liya3dMessageRole.assistant,
          createdAt: DateTime.now(),
          suggestions: data.suggestions,
        );
      }
      
      if (assistantMsg != null) {
        _messages.add(assistantMsg);
        _lastAssistantMessage = assistantMsg;

        // Update suggestions
        if (data.suggestions != null && data.suggestions!.isNotEmpty) {
          _suggestions = data.suggestions!;
        } else if (assistantMsg.suggestions != null) {
          _suggestions = assistantMsg.suggestions!;
        }

        onAssistantMessage?.call(assistantMsg);
      }

      notifyListeners();
      return data;
    } else {
      // Remove temp user message on error
      _messages.removeWhere((m) => m.id == tempUserMessage.id);
      _error = response.error;
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all messages and start new session
  Future<void> clearSession() async {
    _messages.clear();
    _sessionId = null;
    _historyLoaded = false;
    _lastAssistantMessage = null;
    _suggestions = [];
    _error = null;
    await _storageService.clearSessionId();
    notifyListeners();
  }

  /// Get message count
  int get messageCount => _messages.length;

  /// Check if there are any messages
  bool get hasMessages => _messages.isNotEmpty;

  /// Check if there's a last assistant message to replay
  bool get canReplay => _lastAssistantMessage != null && _lastAssistantMessage!.content.isNotEmpty;

  @override
  void dispose() {
    super.dispose();
  }
}
