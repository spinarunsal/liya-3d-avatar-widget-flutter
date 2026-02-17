import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';
import '../i18n/liya3d_translations.dart';

/// Chat input bar with text field, mic button, and send button
class Liya3dChatInput extends StatefulWidget {
  /// Callback when message is submitted
  final ValueChanged<String> onSubmit;

  /// Callback when mic button is pressed
  final VoidCallback? onMicPressed;

  /// Callback when file upload button is pressed
  final VoidCallback? onFilePressed;

  /// Whether voice input is enabled
  final bool showVoice;

  /// Whether voice feature is available (account type)
  final bool voiceEnabled;

  /// Whether currently recording
  final bool isRecording;

  /// Whether file upload is enabled
  final bool showFileUpload;

  /// Whether input is disabled (loading state)
  final bool isDisabled;

  /// Placeholder text
  final String? placeholder;

  /// Translations
  final Liya3dTranslations translations;

  /// Current voice transcript (shown while recording)
  final String? transcript;

  const Liya3dChatInput({
    super.key,
    required this.onSubmit,
    this.onMicPressed,
    this.onFilePressed,
    this.showVoice = true,
    this.voiceEnabled = true,
    this.isRecording = false,
    this.showFileUpload = true,
    this.isDisabled = false,
    this.placeholder,
    required this.translations,
    this.transcript,
  });

  @override
  State<Liya3dChatInput> createState() => _Liya3dChatInputState();
}

class _Liya3dChatInputState extends State<Liya3dChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(Liya3dChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text field with transcript while recording
    if (widget.isRecording && widget.transcript != null) {
      _controller.text = widget.transcript!;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isDisabled) {
      widget.onSubmit(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: Liya3dGlassDecoration.inputBar(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // File upload button
                if (widget.showFileUpload)
                  _buildIconButton(
                    icon: Icons.attach_file,
                    onPressed: widget.onFilePressed,
                    isDisabled: widget.isDisabled,
                  ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.isDisabled && !widget.isRecording,
                    style: const TextStyle(
                      color: Liya3dColors.textLight,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isRecording
                          ? widget.translations.listening
                          : (widget.placeholder ?? widget.translations.placeholder),
                      hintStyle: TextStyle(
                        color: Liya3dColors.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),

                // Mic button
                if (widget.showVoice && widget.voiceEnabled)
                  _buildMicButton(),

                // Send button
                _buildSendButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Liya3dColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Liya3dColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? Liya3dColors.textMuted
              : Liya3dColors.primary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onMicPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          gradient: widget.isRecording
              ? Liya3dColors.dangerGradient
              : null,
          color: widget.isRecording
              ? null
              : Liya3dColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isRecording
                ? Liya3dColors.danger.withOpacity(0.5)
                : Liya3dColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          widget.isRecording ? Icons.stop : Icons.mic,
          color: widget.isRecording
              ? Colors.white
              : (widget.isDisabled ? Liya3dColors.textMuted : Liya3dColors.primary),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && !widget.isDisabled;

    return GestureDetector(
      onTap: canSend ? _handleSubmit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          gradient: canSend ? Liya3dColors.primaryGradient : null,
          color: canSend ? null : Liya3dColors.bgDarkTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.send,
          color: canSend ? Colors.white : Liya3dColors.textMuted,
          size: 18,
        ),
      ),
    );
  }
}
