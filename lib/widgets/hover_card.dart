import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color baseColor;
  final Color hoverColor;
  final BorderRadius? borderRadius;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.baseColor = AppColors.surface,
    this.hoverColor = AppColors.surfaceRaised,
    this.borderRadius,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final showHoverColor = _isHovering || _isFocused;

    return FocusableActionDetector(
      mouseCursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (isHovering) {
        setState(() => _isHovering = isHovering);
      },
      onShowFocusHighlight: (isFocused) {
        setState(() => _isFocused = isFocused);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            if (widget.onTap != null) {
              widget.onTap!();
            }
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: showHoverColor ? widget.hoverColor : widget.baseColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
