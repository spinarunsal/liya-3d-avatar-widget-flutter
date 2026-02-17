import 'dart:ui';
import 'package:flutter/material.dart';
import 'liya3d_colors.dart';

/// Liquid Glass decoration helper for consistent styling
class Liya3dGlassDecoration {
  Liya3dGlassDecoration._();

  /// Standard glass effect decoration
  static BoxDecoration glass({
    double opacity = 0.1,
    double borderOpacity = 0.15,
    double borderRadius = 16,
    List<BoxShadow>? shadows,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: shadows,
    );
  }

  /// Glass decoration with gradient background
  static BoxDecoration glassGradient({
    required Gradient gradient,
    double borderOpacity = 0.15,
    double borderRadius = 16,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: shadows,
    );
  }

  /// Toggle button decoration
  static BoxDecoration toggleButton({bool isRecording = false}) {
    return BoxDecoration(
      gradient: isRecording ? Liya3dColors.dangerGradient : Liya3dColors.primaryGradient,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (isRecording ? Liya3dColors.danger : Liya3dColors.primary).withOpacity(0.4),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 0,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Header glass decoration
  static BoxDecoration header() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      border: Border(
        bottom: BorderSide(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
    );
  }

  /// Message bubble decoration
  static BoxDecoration messageBubble({required bool isUser}) {
    if (isUser) {
      return BoxDecoration(
        color: Liya3dColors.userBubbleBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: Liya3dColors.userBubbleBorder,
          width: 1,
        ),
      );
    } else {
      return BoxDecoration(
        color: Liya3dColors.assistantBubbleBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: Liya3dColors.assistantBubbleBorder,
          width: 1,
        ),
      );
    }
  }

  /// Chat input bar decoration
  static BoxDecoration inputBar() {
    return BoxDecoration(
      gradient: Liya3dColors.inputGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Liya3dColors.inputBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Suggestion chip decoration
  static BoxDecoration suggestionChip() {
    return BoxDecoration(
      color: Liya3dColors.suggestionBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Liya3dColors.suggestionBorder,
        width: 1,
      ),
    );
  }

  /// Kiosk status indicator decoration
  static BoxDecoration statusIndicator() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1,
      ),
    );
  }

  /// Kiosk messages area decoration
  static BoxDecoration kioskMessagesArea() {
    return BoxDecoration(
      gradient: Liya3dColors.kioskMessagesGradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 50,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.08),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Kiosk mic button decoration
  static BoxDecoration kioskMicButton({bool isRecording = false, bool isDisabled = false}) {
    final baseGradient = isRecording
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE6EF4444), // red-500 90%
              Color(0xE6F97316), // orange-500 90%
            ],
          )
        : Liya3dColors.primaryGradient;

    return BoxDecoration(
      gradient: baseGradient,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: (isRecording ? Liya3dColors.danger : Liya3dColors.primary).withOpacity(isDisabled ? 0.15 : 0.35),
          blurRadius: 36,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }

  /// Premium overlay decoration
  static BoxDecoration premiumOverlay() {
    return BoxDecoration(
      gradient: Liya3dColors.premiumGradient,
      borderRadius: BorderRadius.circular(16),
    );
  }

  /// Premium icon circle decoration
  static BoxDecoration premiumIconCircle() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Liya3dColors.premium,
          Liya3dColors.premiumDark,
        ],
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Liya3dColors.premium.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

/// Widget wrapper for backdrop blur effect
class Liya3dBlurredContainer extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final double borderRadius;

  const Liya3dBlurredContainer({
    super.key,
    required this.child,
    this.sigmaX = 20,
    this.sigmaY = 20,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }
}
