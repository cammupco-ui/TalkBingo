import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkbingo_app/services/sound_service.dart';

/// Animated button with hover and tap scale effects inspired by Animate UI
/// 
/// Features:
/// - Hover scale animation (web/desktop)
/// - Tap scale animation (mobile/all platforms)
/// - Haptic feedback on tap
/// - Reduced motion support
/// - Customizable colors, padding, and border radius
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double hoverScale;
  final double tapScale;
  final Duration duration;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final ButtonStyle? style;
  final bool enableHaptic;
  
  const AnimatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hoverScale = 1.05,
    this.tapScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.style,
    this.enableHaptic = true,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isHovered = false;
  bool _isTapped = false;
  
  @override
  Widget build(BuildContext context) {
    // Check for reduced motion
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    // Calculate current scale
    final double scale = reduceMotion 
        ? 1.0 
        : (_isTapped 
            ? widget.tapScale 
            : (_isHovered ? widget.hoverScale : 1.0));
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null 
            ? (_) => setState(() => _isTapped = true)
            : null,
        onTapUp: (_) {
            if (widget.onPressed != null) {
                setState(() => _isTapped = false);
                if (widget.enableHaptic) {
                  HapticFeedback.mediumImpact();
                }
                SoundService().playButtonSound();
                widget.onPressed?.call();
            } else {
                SoundService().playDisabledSound();
            }
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: widget.style ?? ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              padding: widget.padding,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(8),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Animated text button variant
class AnimatedTextButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double hoverScale;
  final double tapScale;
  final Duration duration;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final ButtonStyle? style;
  final bool enableHaptic;
  
  const AnimatedTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hoverScale = 1.05,
    this.tapScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.foregroundColor,
    this.padding,
    this.style,
    this.enableHaptic = true,
  }) : super(key: key);

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton> {
  bool _isHovered = false;
  bool _isTapped = false;
  
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final double scale = reduceMotion 
        ? 1.0 
        : (_isTapped 
            ? widget.tapScale 
            : (_isHovered ? widget.hoverScale : 1.0));
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null 
            ? (_) => setState(() => _isTapped = true)
            : null,
        onTapUp: (_) {
            if (widget.onPressed != null) {
                setState(() => _isTapped = false);
                if (widget.enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                SoundService().playButtonSound();
                widget.onPressed?.call();
            } else {
                SoundService().playDisabledSound();
            }
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: TextButton(
            onPressed: widget.onPressed,
            style: widget.style ?? TextButton.styleFrom(
              foregroundColor: widget.foregroundColor,
              padding: widget.padding,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Animated outlined button variant
class AnimatedOutlinedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double hoverScale;
  final double tapScale;
  final Duration duration;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final ButtonStyle? style;
  final bool enableHaptic;
  
  const AnimatedOutlinedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hoverScale = 1.05,
    this.tapScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.style,
    this.enableHaptic = true,
  }) : super(key: key);

  @override
  State<AnimatedOutlinedButton> createState() => _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<AnimatedOutlinedButton> {
  bool _isHovered = false;
  bool _isTapped = false;
  
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final double scale = reduceMotion 
        ? 1.0 
        : (_isTapped 
            ? widget.tapScale 
            : (_isHovered ? widget.hoverScale : 1.0));
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null 
            ? (_) => setState(() => _isTapped = true)
            : null,
        onTapUp: (_) {
            if (widget.onPressed != null) {
                setState(() => _isTapped = false);
                if (widget.enableHaptic) {
                  HapticFeedback.mediumImpact();
                }
                SoundService().playButtonSound();
                widget.onPressed?.call();
            } else {
                SoundService().playDisabledSound();
            }
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: widget.style ?? OutlinedButton.styleFrom(
              foregroundColor: widget.foregroundColor,
              side: BorderSide(
                color: widget.borderColor ?? 
                    (widget.foregroundColor ?? Theme.of(context).primaryColor),
              ),
              padding: widget.padding,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(8),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Animated icon button variant
class AnimatedIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double hoverScale;
  final double tapScale;
  final Duration duration;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final bool enableHaptic;
  
  const AnimatedIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.hoverScale = 1.1,
    this.tapScale = 0.9,
    this.duration = const Duration(milliseconds: 150),
    this.color,
    this.iconSize,
    this.padding,
    this.enableHaptic = true,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  bool _isHovered = false;
  bool _isTapped = false;
  
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final double scale = reduceMotion 
        ? 1.0 
        : (_isTapped 
            ? widget.tapScale 
            : (_isHovered ? widget.hoverScale : 1.0));
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null 
            ? (_) => setState(() => _isTapped = true)
            : null,
        onTapUp: (_) {
            if (widget.onPressed != null) {
                setState(() => _isTapped = false);
                if (widget.enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                SoundService().playButtonSound();
                widget.onPressed?.call();
            } else {
                SoundService().playDisabledSound();
            }
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: IconButton(
            icon: widget.icon,
            onPressed: widget.onPressed,
            color: widget.color,
            iconSize: widget.iconSize,
            padding: widget.padding ?? const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}