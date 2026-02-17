import 'package:flutter/material.dart';

/// Liya 3D Avatar Widget color palette
/// Matches Vue.js widget colors exactly
class Liya3dColors {
  Liya3dColors._();

  // Primary colors
  static const Color primary = Color(0xFF6366F1);        // indigo-500
  static const Color primaryHover = Color(0xFF4F46E5);   // indigo-600
  static const Color secondary = Color(0xFF8B5CF6);      // violet-500

  // Background colors (Dark theme - default)
  static const Color bgDark = Color(0xFF0F172A);         // slate-900
  static const Color bgDarkSecondary = Color(0xFF1E293B); // slate-800
  static const Color bgDarkTertiary = Color(0xFF334155);  // slate-700

  // Background colors (Light theme)
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF1F5F9); // slate-100
  static const Color bgLightTertiary = Color(0xFFE2E8F0);  // slate-200

  // Text colors
  static const Color textLight = Color(0xFFF1F5F9);      // slate-100
  static const Color textMuted = Color(0xFF94A3B8);       // slate-400
  static const Color textDark = Color(0xFF1E293B);        // slate-800

  // Status indicator colors
  static const Color statusIdle = Color(0xFF22C55E);      // green-500
  static const Color statusListening = Color(0xFF3B82F6); // blue-500
  static const Color statusPreparing = Color(0xFFF59E0B); // amber-500
  static const Color statusSpeaking = Color(0xFF8B5CF6);  // violet-500

  // Danger/Error colors
  static const Color danger = Color(0xFFEF4444);          // red-500
  static const Color dangerDark = Color(0xFFDC2626);      // red-600

  // Premium colors
  static const Color premium = Color(0xFFF59E0B);         // amber-500
  static const Color premiumDark = Color(0xFFD97706);     // amber-600

  // Suggestion chip colors
  static const Color suggestionBg = Color(0x266366F1);    // primary with 15% opacity
  static const Color suggestionBorder = Color(0x666366F1); // primary with 40% opacity
  static const Color suggestionText = Color(0xFFA5B4FC);  // indigo-300

  // Glass effect colors
  static const Color glassWhite = Color(0x1AFFFFFF);      // white 10%
  static const Color glassBorder = Color(0x26FFFFFF);     // white 15%
  static const Color glassHighlight = Color(0x0DFFFFFF);  // white 5%

  // Message bubble colors
  static const Color userBubbleBg = Color(0x596366F1);    // primary 35%
  static const Color userBubbleBorder = Color(0x806366F1); // primary 50%
  static const Color assistantBubbleBg = Color(0x99334155); // slate-700 60%
  static const Color assistantBubbleBorder = Color(0x26FFFFFF); // white 15%

  // Input bar colors
  static const Color inputBg = Color(0x80334155);         // slate-700 50%
  static const Color inputBgDark = Color(0xB31E293B);     // slate-800 70%
  static const Color inputBorder = Color(0x1AFFFFFF);     // white 10%

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE66366F1), // primary 90%
      Color(0xE68B5CF6), // secondary 90%
    ],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE6DC2626), // red-600 90%
      Color(0xE6B91C1C), // red-700 90%
    ],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x26F59E0B), // amber-500 15%
      Color(0x33D97706), // amber-600 20%
    ],
  );

  static const LinearGradient inputGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80334155), // slate-700 50%
      Color(0xB31E293B), // slate-800 70%
    ],
  );

  static const LinearGradient kioskMessagesGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xB31E293B), // slate-800 70%
      Color(0xCC0F172A), // slate-900 80%
    ],
  );
}
