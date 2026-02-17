/// Liya 3D Avatar Widget translations
/// Matches Vue.js widget translations exactly
class Liya3dTranslations {
  final String locale;

  // Widget
  final String openChat;
  final String closeChat;
  final String online;
  final String preparing;
  final String speaking;

  // Chat
  final String placeholder;
  final String send;
  final String typing;
  final String welcomeMessage;
  final List<String> welcomeSuggestions;

  // Voice
  final String startRecording;
  final String stopRecording;
  final String listening;
  final String thinking;
  final String speakToMic;

  // Kiosk
  final String close;
  final String cancel;
  final String refresh;
  final String ready;

  // Preparing messages (rotating)
  final List<String> preparingMessages;

  // Avatar
  final String replay;
  final String stop;

  // Errors
  final String connectionError;
  final String sendError;
  final String featureNotAvailable;
  final String upgradeToPremium;
  final String upgradeToPremiumPlus;

  // Branding
  final String poweredBy;

  // Language
  final String language;
  final String turkish;
  final String english;

  const Liya3dTranslations({
    required this.locale,
    required this.openChat,
    required this.closeChat,
    required this.online,
    required this.preparing,
    required this.speaking,
    required this.placeholder,
    required this.send,
    required this.typing,
    required this.welcomeMessage,
    required this.welcomeSuggestions,
    required this.startRecording,
    required this.stopRecording,
    required this.listening,
    required this.thinking,
    required this.speakToMic,
    required this.close,
    required this.cancel,
    required this.refresh,
    required this.ready,
    required this.preparingMessages,
    required this.replay,
    required this.stop,
    required this.connectionError,
    required this.sendError,
    required this.featureNotAvailable,
    required this.upgradeToPremium,
    required this.upgradeToPremiumPlus,
    required this.poweredBy,
    required this.language,
    required this.turkish,
    required this.english,
  });

  /// Turkish translations
  static const Liya3dTranslations tr = Liya3dTranslations(
    locale: 'tr',
    openChat: 'Sohbeti Aç',
    closeChat: 'Sohbeti Kapat',
    online: 'Çevrimiçi',
    preparing: 'Hazırlanıyor',
    speaking: 'Konuşuyor',
    placeholder: 'Mesajınızı yazın...',
    send: 'Gönder',
    typing: 'yazıyor...',
    welcomeMessage: 'Merhaba! Size nasıl yardımcı olabilirim?',
    welcomeSuggestions: [
      'Bana kendinden bahset',
      'Neler yapabilirsin?',
      'Yardım et',
    ],
    startRecording: 'Kayda başla',
    stopRecording: 'Kaydı durdur',
    listening: 'Dinliyorum...',
    thinking: 'Düşünüyorum...',
    speakToMic: 'Mikrofona konuşun',
    close: 'Kapat',
    cancel: 'İptal',
    refresh: 'Yenile',
    ready: 'Hazır',
    preparingMessages: [
      'Düşünüyorum...',
      'Yanıt hazırlıyorum...',
      'Bir saniye...',
      'Hemen cevaplıyorum...',
    ],
    replay: 'Tekrar Oynat',
    stop: 'Durdur',
    connectionError: 'Bağlantı hatası. Lütfen tekrar deneyin.',
    sendError: 'Mesaj gönderilemedi. Lütfen tekrar deneyin.',
    featureNotAvailable: 'Bu özellik mevcut değil.',
    upgradeToPremium: 'Bu özelliği kullanmak için Premium\'a yükseltin.',
    upgradeToPremiumPlus: 'Bu özelliği kullanmak için Premium Plus\'a yükseltin.',
    poweredBy: 'Powered by',
    language: 'Dil',
    turkish: 'Türkçe',
    english: 'İngilizce',
  );

  /// English translations
  static const Liya3dTranslations en = Liya3dTranslations(
    locale: 'en',
    openChat: 'Open Chat',
    closeChat: 'Close Chat',
    online: 'Online',
    preparing: 'Preparing',
    speaking: 'Speaking',
    placeholder: 'Type your message...',
    send: 'Send',
    typing: 'typing...',
    welcomeMessage: 'Hello! How can I help you?',
    welcomeSuggestions: [
      'Tell me about yourself',
      'What can you do?',
      'Help me',
    ],
    startRecording: 'Start recording',
    stopRecording: 'Stop recording',
    listening: 'Listening...',
    thinking: 'Thinking...',
    speakToMic: 'Speak to the microphone',
    close: 'Close',
    cancel: 'Cancel',
    refresh: 'Refresh',
    ready: 'Ready',
    preparingMessages: [
      'Thinking...',
      'Preparing response...',
      'Just a moment...',
      'Working on it...',
    ],
    replay: 'Replay',
    stop: 'Stop',
    connectionError: 'Connection error. Please try again.',
    sendError: 'Failed to send message. Please try again.',
    featureNotAvailable: 'This feature is not available.',
    upgradeToPremium: 'Upgrade to Premium to use this feature.',
    upgradeToPremiumPlus: 'Upgrade to Premium Plus to use this feature.',
    poweredBy: 'Powered by',
    language: 'Language',
    turkish: 'Turkish',
    english: 'English',
  );

  /// Get translations by locale
  static Liya3dTranslations byLocale(String? locale) {
    switch (locale?.toLowerCase()) {
      case 'tr':
        return tr;
      case 'en':
      default:
        return en;
    }
  }
}

/// Mixin for accessing translations in widgets
mixin Liya3dTranslationsMixin {
  Liya3dTranslations _translations = Liya3dTranslations.tr;

  Liya3dTranslations get t => _translations;

  void setLocale(String? locale) {
    _translations = Liya3dTranslations.byLocale(locale);
  }
}
