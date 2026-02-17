import 'package:flutter/material.dart';
import '../models/liya3d_message.dart';
import 'liya3d_message_bubble.dart';

/// Scrollable message list with auto-scroll to bottom
class Liya3dMessageList extends StatefulWidget {
  /// List of messages to display
  final List<Liya3dMessage> messages;

  /// Callback when a suggestion is tapped
  final ValueChanged<String>? onSuggestionTap;

  /// Whether to auto-scroll to bottom on new messages
  final bool autoScroll;

  const Liya3dMessageList({
    super.key,
    required this.messages,
    this.onSuggestionTap,
    this.autoScroll = true,
  });

  @override
  State<Liya3dMessageList> createState() => _Liya3dMessageListState();
}

class _Liya3dMessageListState extends State<Liya3dMessageList> {
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void didUpdateWidget(Liya3dMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-scroll when new messages are added
    if (widget.autoScroll && widget.messages.length > _previousMessageCount) {
      _scrollToBottom();
    }
    _previousMessageCount = widget.messages.length;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return Liya3dMessageBubble(
          message: message,
          onSuggestionTap: widget.onSuggestionTap,
        );
      },
    );
  }
}
