import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/liya3d_message.dart';
import '../models/liya3d_enums.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';

/// Chat message bubble with Liquid Glass styling
class Liya3dMessageBubble extends StatelessWidget {
  /// The message to display
  final Liya3dMessage message;

  /// Callback when a suggestion is tapped
  final ValueChanged<String>? onSuggestionTap;

  /// Maximum width ratio (0.0 - 1.0)
  final double maxWidthRatio;

  const Liya3dMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
    this.maxWidthRatio = 0.8,
  });

  bool get isUser => message.role == Liya3dMessageRole.user;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * maxWidthRatio;

    // Typing indicator
    if (message.isTyping) {
      return _buildTypingIndicator();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 8,
          right: isUser ? 8 : 48,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            ClipRRect(
              borderRadius: _getBorderRadius(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: Liya3dGlassDecoration.messageBubble(isUser: isUser),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      Text(
                        message.content,
                        style: TextStyle(
                          color: Liya3dColors.textLight,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      // Response time (for assistant messages)
                      if (!isUser && message.responseTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${message.responseTime!.toStringAsFixed(1)}s',
                            style: TextStyle(
                              color: Liya3dColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Suggestions (for assistant messages)
            if (!isUser &&
                message.suggestions != null &&
                message.suggestions!.isNotEmpty)
              _buildSuggestions(),
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(16),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: Liya3dGlassDecoration.messageBubble(isUser: false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Liya3dColors.textMuted.withOpacity(0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.suggestions!.map((suggestion) {
          return GestureDetector(
            onTap: () => onSuggestionTap?.call(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: Liya3dGlassDecoration.suggestionChip(),
              child: Text(
                suggestion,
                style: TextStyle(
                  color: Liya3dColors.suggestionText,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
