import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/liya3d_enums.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';
import '../i18n/liya3d_translations.dart';

/// Header bar with assistant name, status, and controls
class Liya3dHeader extends StatelessWidget {
  /// Assistant name
  final String? assistantName;

  /// Current avatar status
  final Liya3dAvatarStatus status;

  /// Whether replay button should be shown
  final bool canReplay;

  /// Whether currently speaking
  final bool isSpeaking;

  /// Current locale
  final String locale;

  /// Translations
  final Liya3dTranslations translations;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  /// Callback when replay button is pressed
  final VoidCallback? onReplay;

  /// Callback when stop button is pressed
  final VoidCallback? onStop;

  /// Callback when language toggle is pressed
  final VoidCallback? onLanguageToggle;

  /// Whether close button is enabled
  final bool closeButtonEnabled;

  const Liya3dHeader({
    super.key,
    this.assistantName,
    required this.status,
    this.canReplay = false,
    this.isSpeaking = false,
    required this.locale,
    required this.translations,
    this.onClose,
    this.onReplay,
    this.onStop,
    this.onLanguageToggle,
    this.closeButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: Liya3dGlassDecoration.header(),
          child: Row(
            children: [
              // Status dot
              _buildStatusDot(),
              const SizedBox(width: 12),

              // Assistant name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      assistantName ?? 'Liya',
                      style: const TextStyle(
                        color: Liya3dColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: Liya3dColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Replay/Stop button
              if (isSpeaking)
                _buildControlButton(
                  icon: Icons.stop,
                  onPressed: onStop,
                  tooltip: translations.stop,
                )
              else if (canReplay)
                _buildControlButton(
                  icon: Icons.replay,
                  onPressed: onReplay,
                  tooltip: translations.replay,
                ),

              // Language toggle
              _buildLanguageToggle(),

              // Close button
              if (closeButtonEnabled)
                _buildControlButton(
                  icon: Icons.close,
                  onPressed: onClose,
                  tooltip: translations.close,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    Color dotColor;
    bool shouldPulse = false;

    switch (status) {
      case Liya3dAvatarStatus.idle:
        dotColor = Liya3dColors.statusIdle;
        break;
      case Liya3dAvatarStatus.listening:
        dotColor = Liya3dColors.statusListening;
        shouldPulse = true;
        break;
      case Liya3dAvatarStatus.preparing:
        dotColor = Liya3dColors.statusPreparing;
        shouldPulse = true;
        break;
      case Liya3dAvatarStatus.speaking:
        dotColor = Liya3dColors.statusSpeaking;
        shouldPulse = true;
        break;
    }

    return _StatusDot(color: dotColor, shouldPulse: shouldPulse);
  }

  String _getStatusText() {
    switch (status) {
      case Liya3dAvatarStatus.idle:
        return translations.online;
      case Liya3dAvatarStatus.listening:
        return translations.listening;
      case Liya3dAvatarStatus.preparing:
        return translations.preparing;
      case Liya3dAvatarStatus.speaking:
        return translations.speaking;
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Liya3dColors.textLight,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onLanguageToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            locale.toUpperCase(),
            style: const TextStyle(
              color: Liya3dColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated status dot with pulse effect
class _StatusDot extends StatefulWidget {
  final Color color;
  final bool shouldPulse;

  const _StatusDot({
    required this.color,
    required this.shouldPulse,
  });

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
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
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
            boxShadow: widget.shouldPulse
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 8 * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
