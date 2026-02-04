import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart'; // Added for Shake
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
  late AnimationController _shakeController; // New for Locked Shake
  
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
    
    // Hover controller for liquid fill effect
    // INCREASED DURATION: 0.8s for smoother fill as requested
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), 
    );
    
    // Tap controller for bounce effect
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Shake controller for locked items
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      curve: Curves.easeInOutCubic, // Smoother curve
    ));
    
    // Hover scale animation (1.0 → 1.03)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    // Tap bounce animation sequence (Elastic)
    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95) // Deeper press
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)), // Elastic bounce back
        weight: 60,
      ),
    ]).animate(_tapController);
  }
  
  @override
  void didUpdateWidget(LiquidBingoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
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
    _shakeController.dispose();
    super.dispose();
  }
  
  // Helper getters
  bool get _isFilled => widget.owner != null && widget.owner!.isNotEmpty && widget.owner != 'X';
  bool get _isLocked => widget.owner == 'LOCKED' || widget.owner == 'X';
  bool get _canSelect => !_isFilled && !_isLocked;
  
  Color get _fillColor {
    if (widget.owner == 'A') return AppColors.hostPrimary;
    if (widget.owner == 'B') return AppColors.guestPrimary;
    if (_isLocked) return Colors.grey.shade600;
    return Colors.transparent;
  }
  
  Color get _hoverColor => widget.isHost ? AppColors.hostPrimary : AppColors.guestPrimary;
  
  void _handleTap() {
    // 1. Shake if Locked (Visual Feedback) but ALLOW Tap to proceed
    if (_isLocked) {
       HapticFeedback.lightImpact(); 
       _shakeController.forward(from: 0);
       // Fall through to execute onTap so GameScreen can handle the "Challenge" logic
    } else if (!_canSelect && !_isFilled) {
       // If not locked but not selectable (e.g. turn mismatch managed by parent, or filled?),
       // Actually _canSelect is !_isFilled && !_isLocked.
       // So this block handles: Filled tiles? Or just other cases?
       // If filled, usually we ignore.
       return;
    }

    // 2. Click Logic
    // Allow tap if selectable OR Locked (to trigger mini game)
    if (_canSelect || _isLocked) {
      // Haptic feedback for tactile response
      HapticFeedback.mediumImpact();
      
      // Play tap bounce animation
      _tapController.forward(from: 0);
      
      // Execute callback
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine animations
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _tapController]),
      builder: (context, child) {
        final double scale = _scaleAnimation.value * _tapScaleAnimation.value;
        
        // Wrap with Shake Animation from flutter_animate
        // Note: effectively 0-1, we use ShakeEffect to interpret it
        return Animate(
          controller: _shakeController,
          autoPlay: false,
          effects: const [
            ShakeEffect(hz: 10, offset: const Offset(4, 0), curve: Curves.easeInOut, duration: Duration(milliseconds: 500))
          ],
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _fillColor.withOpacity(widget.isHovered && _canSelect ? 0.3 : 0.15),
                    offset: Offset(0, widget.isHovered ? 8 : 4),
                    blurRadius: widget.isHovered ? 20 : 10,
                    spreadRadius: widget.isHovered ? 2 : 0,
                  ),
                  if (_canSelect && widget.isHovered)
                    BoxShadow(
                      color: _hoverColor.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
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
                              : (widget.isHovered && _canSelect ? _hoverColor : Colors.grey.withOpacity(0.2)),
                          width: widget.isWinningTile ? 3.0 : (widget.isHovered ? 2.0 : 1.0),
                        )
                      : null,
                    borderRadius: BorderRadius.circular(12),
                    gradient: _isFilled
                        ? (_isLocked 
                            ? LinearGradient( // Locked Gradient (Dark Black/Grey)
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.black87, Colors.black54],
                              )
                            : null) 
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey.shade50],
                          ),
                  ),
                  child: Stack(
                    children: [
                      // Watermark for MP/CP
                      if (widget.owner == 'A')
                        const Center(
                          child: Text(
                            "M",
                            style: TextStyle(
                              fontFamily: 'NURA',
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white12, // Very subtle transparent white
                            ),
                          ),
                        ),
                      if (widget.owner == 'B')
                        const Center(
                          child: Text(
                            "C",
                            style: TextStyle(
                              fontFamily: 'NURA',
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white12, 
                            ),
                          ),
                        ),

                      // Base Text
                      Center(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontFamily: 'NURA',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _isLocked ? Colors.grey.shade400 : AppColors.textDark,
                          ),
                        ),
                      ),
                      
                      // Locked Icon (Centered, Large, Semi-transparent)
                      if (_isLocked)
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                               color: Colors.black.withOpacity(0.3), // Darker semi-transparent backing shape
                               shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock, color: Colors.white.withOpacity(0.9), size: 28),
                          ),
                        ),
                      
                      // Liquid Fill
                      // Use IgnorePointer for visual layers so InkWell gets clicks
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            if (_isFilled) {
                               return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_fillColor, _fillColor.withOpacity(0.9)],
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
                                    colors: [_fillColor, _fillColor.withOpacity(0.8)],
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
                      ),
                      
                      // Winning Shimmer
                      if (widget.isWinningTile)
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return Container(
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
                                      (_shimmerController.value - 0.2).clamp(0.0, 1.0),
                                      _shimmerController.value,
                                      (_shimmerController.value + 0.2).clamp(0.0, 1.0),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // RIPPLE OVERLAY (Material InkWell)
                      // This must be on top to capture touches and show ripple
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleTap,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: _hoverColor.withOpacity(0.3),
                          highlightColor: _hoverColor.withOpacity(0.1),
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
