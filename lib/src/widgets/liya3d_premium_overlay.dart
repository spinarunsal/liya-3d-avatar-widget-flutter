import 'package:flutter/material.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';
import '../i18n/liya3d_translations.dart';

/// Premium upgrade overlay shown when user doesn't have access
class Liya3dPremiumOverlay extends StatelessWidget {
  /// Translations
  final Liya3dTranslations translations;

  /// Whether Premium Plus is required (vs just Premium)
  final bool requiresPremiumPlus;

  /// Callback when upgrade button is pressed
  final VoidCallback? onUpgrade;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  const Liya3dPremiumOverlay({
    super.key,
    required this.translations,
    this.requiresPremiumPlus = false,
    this.onUpgrade,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Liya3dGlassDecoration.premiumOverlay(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shield icon
          Container(
            width: 72,
            height: 72,
            decoration: Liya3dGlassDecoration.premiumIconCircle(),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            requiresPremiumPlus ? 'Premium Plus' : 'Premium',
            style: const TextStyle(
              color: Liya3dColors.textLight,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            requiresPremiumPlus
                ? translations.upgradeToPremiumPlus
                : translations.upgradeToPremium,
            style: TextStyle(
              color: Liya3dColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Upgrade button
          if (onUpgrade != null)
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Liya3dColors.premium,
                      Liya3dColors.premiumDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Liya3dColors.premium.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Close button
          if (onClose != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: onClose,
                child: Text(
                  translations.close,
                  style: TextStyle(
                    color: Liya3dColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
