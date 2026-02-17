/// Widget display modes
enum Liya3dWidgetMode {
  /// Standard mode - toggle button + expandable chat panel
  standard,

  /// Modal kiosk mode - full screen modal overlay, voice-first
  modalKiosk,

  /// Kiosk mode - full screen, voice-first
  kiosk,
}

/// Widget position on screen
enum Liya3dWidgetPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft,
}

/// Message sender role
enum Liya3dMessageRole {
  user,
  assistant,
}

/// Avatar status states
enum Liya3dAvatarStatus {
  /// Ready and waiting
  idle,

  /// Listening to user speech
  listening,

  /// Processing/preparing response
  preparing,

  /// Speaking with lip-sync
  speaking,
}

/// Account type for access control
enum Liya3dAccountType {
  standard,
  premium,
  premiumPlus,
  systemAdmin,
}

extension Liya3dAccountTypeExtension on Liya3dAccountType {
  static Liya3dAccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'premium':
        return Liya3dAccountType.premium;
      case 'premium_plus':
        return Liya3dAccountType.premiumPlus;
      case 'system_admin':
        return Liya3dAccountType.systemAdmin;
      default:
        return Liya3dAccountType.standard;
    }
  }

  String get value {
    switch (this) {
      case Liya3dAccountType.standard:
        return 'standard';
      case Liya3dAccountType.premium:
        return 'premium';
      case Liya3dAccountType.premiumPlus:
        return 'premium_plus';
      case Liya3dAccountType.systemAdmin:
        return 'system_admin';
    }
  }
}
