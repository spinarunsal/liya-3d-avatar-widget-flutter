import 'package:flutter/material.dart';
import '../utils/liya3d_colors.dart';
import '../utils/liya3d_glass_decoration.dart';

/// Floating toggle button for opening/closing the chat widget
class Liya3dToggleButton extends StatefulWidget {
  /// Whether the widget is currently open
  final bool isOpen;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether to animate the button
  final bool animate;

  /// Button size
  final double size;

  const Liya3dToggleButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
    this.animate = true,
    this.size = 60,
  });

  @override
  State<Liya3dToggleButton> createState() => _Liya3dToggleButtonState();
}

class _Liya3dToggleButtonState extends State<Liya3dToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate && !widget.isOpen) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(Liya3dToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen) {
      _animationController.stop();
    } else if (widget.animate && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        final bounce = widget.animate && !widget.isOpen
            ? _bounceAnimation.value * 4
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -bounce),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: Liya3dGlassDecoration.toggleButton(),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isOpen
                      ? Icon(
                          Icons.close,
                          key: const ValueKey('close'),
                          color: Colors.white,
                          size: widget.size * 0.4,
                        )
                      : _buildLiyaIcon(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiyaIcon() {
    // Liya "L" icon with sparkles
    return SizedBox(
      key: const ValueKey('liya'),
      width: widget.size * 0.5,
      height: widget.size * 0.5,
      child: Stack(
        children: [
          // L letter
          Center(
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Sparkle top right
          Positioned(
            top: 2,
            right: 2,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.8),
              size: widget.size * 0.15,
            ),
          ),
        ],
      ),
    );
  }
}
