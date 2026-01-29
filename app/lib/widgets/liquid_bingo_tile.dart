import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../styles/app_colors.dart';

class LiquidBingoTile extends StatefulWidget {
  final String text;
  final String? owner; // 'A', 'B', 'LOCKED', 'X', or null/empty
  final bool isHost;
  final bool isHovered;
  final VoidCallback onTap;
  final bool isWinningTile; // New: for bingo line highlighting

  const LiquidBingoTile({
    Key? key,
    required this.text,
    required this.owner,
    required this.isHost,
    this.isHovered = false,
    this.isWinningTile = false,
    required this.onTap,
  }) : super(key: key);

  @override
  State<LiquidBingoTile> createState() => _LiquidBingoTileState();
}

class _LiquidBingoTileState extends State<LiquidBingoTile> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _waveController;
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late AnimationController _shimmerController;
  
  // Animations
  late Animation<double> _fillAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tapScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Wave controller for liquid movement
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // Hover controller for liquid fill effect (Liquid Button style)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Tap controller for bounce effect
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Shimmer for winning tiles (gold glow)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Fill animation (0% → 100% on hover)
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    // Hover scale animation (1.0 → 1.03)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    // Tap bounce animation sequence
    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.97)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_tapController);
  }
  
  @override
  void didUpdateWidget(LiquidBingoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle hover state changes for liquid fill
    if (widget.isHovered != oldWidget.isHovered) {
      if (widget.isHovered && !_isFilled) {
        _hoverController.forward();
      } else if (!widget.isHovered) {
        _hoverController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _hoverController.dispose();
    _tapController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  
  // Helper getters
  bool get _isFilled => widget.owner != null && 
                        widget.owner!.isNotEmpty && 
                        widget.owner != 'X';
  
  bool get _isLocked => widget.owner == 'LOCKED' || widget.owner == 'X';
  
  bool get _canSelect => !_isFilled && !_isLocked;
  
  Color get _fillColor {
    if (widget.owner == 'A') {
      return AppColors.hostPrimary;
    } else if (widget.owner == 'B') {
      return AppColors.guestPrimary;
    } else if (_isLocked) {
      return Colors.grey.shade600;
    }
    return Colors.transparent;
  }
  
  Color get _hoverColor {
    return widget.isHost 
        ? AppColors.hostPrimary 
        : AppColors.guestPrimary;
  }
  
  void _handleTap() {
    // Haptic feedback for tactile response
    HapticFeedback.mediumImpact();
    
    // Play tap bounce animation
    _tapController.forward(from: 0);
    
    // Execute callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController,
        _tapController,
      ]),
      builder: (context, child) {
        // Combine hover and tap scales
        final double scale = _scaleAnimation.value * _tapScaleAnimation.value;
        
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Enhanced 3D shadow system
                boxShadow: [
                  // Main shadow (depth)
                  BoxShadow(
                    color: _fillColor.withOpacity(
                      widget.isHovered && _canSelect ? 0.3 : 0.15
                    ),
                    offset: Offset(0, widget.isHovered ? 8 : 4),
                    blurRadius: widget.isHovered ? 20 : 10,
                    spreadRadius: widget.isHovered ? 2 : 0,
                  ),
                  // Top highlight (3D effect)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                  // Glow effect for selectable tiles
                  if (_canSelect && widget.isHovered)
                    BoxShadow(
                      color: _hoverColor.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  // Gold glow for winning tiles
                  if (widget.isWinningTile)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: (widget.isWinningTile || !_isFilled) 
                      ? Border.all(
                          color: widget.isWinningTile
                              ? Colors.amber
                              : (widget.isHovered && _canSelect
                                  ? _hoverColor
                                  : Colors.grey.withOpacity(0.2)),
                          width: widget.isWinningTile ? 3.0 : (widget.isHovered ? 2.0 : 1.0),
                        )
                      : null,
                    borderRadius: BorderRadius.circular(12),
                    // Gradient for depth when not filled
                    gradient: _isFilled
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                          ),
                  ),
                  child: Stack(
                    children: [
                      // Base text (visible when liquid is low)
                      Center(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontFamily: 'NURA',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _isLocked 
                                ? Colors.grey.shade400
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      
                      // Liquid fill layer (animated)
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          // If filled, show static solid color (no wave)
                          if (_isFilled) {
                             return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _fillColor,
                                      _fillColor.withOpacity(0.9), // Subtle gradient
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.text,
                                    style: const TextStyle(
                                      fontFamily: 'NURA',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                             );
                          }
                          
                          // Otherwise, show wave animation
                          final double fillLevel = _fillAnimation.value;
                          
                          if (fillLevel == 0.0) return const SizedBox.shrink();
                          
                          return ClipPath(
                            clipper: WaveClipper(
                              animationValue: _waveController.value,
                              fillLevel: fillLevel,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _fillColor,
                                    _fillColor.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.text,
                                  style: const TextStyle(
                                    fontFamily: 'NURA',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Shimmer effect for winning tiles (gold wave)
                      if (widget.isWinningTile)
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.amber.withOpacity(0.3 * _shimmerController.value),
                                      Colors.transparent,
                                    ],
                                    stops: [
                                      _shimmerController.value - 0.2,
                                      _shimmerController.value,
                                      _shimmerController.value + 0.2,
                                    ].map((v) => v.clamp(0.0, 1.0)).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      
                      // Locked icon overlay
                      if (_isLocked)
                        Center(
                          child: Icon(
                            Icons.lock,
                            color: _isFilled ? Colors.white70 : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double fillLevel; // 0.0 to 1.0

  WaveClipper({required this.animationValue, required this.fillLevel});

  @override
  Path getClip(Size size) {
    var path = Path();
    
    // Wave parameters
    const double waveHeight = 8.0; // Height of peaks
    // We want the wave to be moving horizontally.
    // The fillLevel determines the "base" height of the water.
    // For a "Rising" animation, we could animate fillLevel. 
    // Here we assume it's settled at 'fillLevel' (1.0 = top, 0.0 = bottom).
    // Note: Canvas coordinates: y=0 is top, y=height is bottom.
    // So "100% full" means y goes up to 0. "0% full" means y stays at size.height.
    
    // Let's make it always "full" for owned tiles, but with a wave at the top?
    // Actually, if it is 100% full, the wave might be clipped off at the top.
    // Let's set the base level slightly below the top if we want to see the wave, 
    // OR just fill it completely. 
    // The user requested a "Liquid" effect. Usually implies movement.
    // If we want the "Liquid Button" effect from the website, the liquid is filling UP on hover.
    // For Bingo, if it's "Owned", it should remain filled.
    // Maybe we keep the wave moving at the top edge?
    
    double yLevel = size.height * (1.0 - fillLevel); 
    // If fillLevel is 1.0, yLevel is 0.
    
    // Let's add the wave processing.
    // We start at bottom-left, go to bottom-right, then trace the wave from right to left at the top?
    // Or easier: Start top-left (with wave offset), go to top-right, bottom-right, bottom-left.
    
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, yLevel);
    
    // Draw Wave from Right to Left (or Left to Right if we reverse points)
    // Let's loop from x = 0 to width
    
    path.reset();
    
    // Start at bottom left
    path.moveTo(0, size.height);
    
    // Loop across width for the top edge (optimized step size)
    for (double x = 0; x <= size.width; x += 2) {
      double y = yLevel + 
          math.sin((x / size.width * 2 * math.pi) + 
                   (animationValue * 2 * math.pi)) * waveHeight;
      path.lineTo(x, y);
    }
    
    // Go down to bottom right
    path.lineTo(size.width, size.height);
    // Go to bottom left
    path.lineTo(0, size.height);
    
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) {
    return animationValue != oldClipper.animationValue || fillLevel != oldClipper.fillLevel;
  }
}
