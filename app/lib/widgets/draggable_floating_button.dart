import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math' as math;

class DraggableFloatingButton extends StatefulWidget {
  final bool isOnChatTab;
  final int unreadCount;
  final VoidCallback onTap;
  final String? latestMessage;
  final Color themeColor;
  final double dragThreshold;

  const DraggableFloatingButton({
    super.key,
    required this.isOnChatTab,
    required this.unreadCount,
    required this.onTap,
    this.latestMessage,
    this.themeColor = AppColors.hostPrimary,
    this.dragThreshold = 5.0,
  });

  @override
  State<DraggableFloatingButton> createState() => _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(300, 500); // Default off-center
  bool _isDragging = false;
  bool _initialized = false;
  Timer? _previewTimer;
  bool _showPreview = false;

  // Idle floating animation
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
    
    // Idle floating animation: continuous gentle bob
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(DraggableFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Show preview if new message arrived while NOT on chat tab
    if (widget.latestMessage != oldWidget.latestMessage && widget.latestMessage != null) {
      if (!widget.isOnChatTab) { 
        setState(() {
          _showPreview = true;
        });
        // 5초 후 사라지는 타이머 제거 (항상 표시)
        _previewTimer?.cancel();
      }
    }
  }
  
  @override
  void dispose() {
    _previewTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosition() async {
    // Wait for frame to get valid MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final double? x = prefs.getDouble('floating_button_x');
      final double? y = prefs.getDouble('floating_button_y');
      
      if (!mounted) return;

      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      
      setState(() {
         if (x != null && y != null) {
            // CRITICAL: Clamp loaded position to current screen size
            // This prevents the button from disappearing if loaded on a smaller screen
            double safeX = x.clamp(16.0, size.width - 70.0); // 70 is max width approx
            double safeY = y.clamp(padding.top + 60, size.height - 100);
            _position = Offset(safeX, safeY);
         } else {
            // Default bottom-right
            double dx = size.width > 100 ? size.width - 80 : 20;
            double dy = size.height > 200 ? size.height - 180 : 200;
            _position = Offset(dx, dy);
         }
         _initialized = true;
      });
    });
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('floating_button_x', _position.dx);
    await prefs.setDouble('floating_button_y', _position.dy);
  }

  double _dragDistance = 0;

  void _onPanStart(DragStartDetails details) {
    _dragDistance = 0;
    _isDragging = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.distance;
    if (_dragDistance > widget.dragThreshold) { 
       setState(() {
         _position += details.delta;
         _isDragging = true;
       });
    }
  }



  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure position is within valid bounds of the PARENT, not the Window
        final double parentWidth = constraints.maxWidth;
        final double parentHeight = constraints.maxHeight;

        // Clamp immediately to ensure visibility if parent resized
        // (e.g. window resize or mobile wrapper)
        final double buttonSize = _isDragging ? 70 : ((_showPreview || (!widget.isOnChatTab && widget.unreadCount > 0)) ? 220 : 60);
        final double safeX = _position.dx.clamp(0.0, parentWidth - buttonSize);
        final double safeY = _position.dy.clamp(0.0, parentHeight - buttonSize);
        
        // If clamp changed status essentially, update _position (optional, avoided for perf during build)

        final bool isChat = widget.isOnChatTab;
        final Color bgColor = isChat 
            ? Colors.grey.withValues(alpha: 0.7) 
            : widget.themeColor.withValues(alpha: 0.85);

        return Stack(
          children: [
            Positioned(
              left: safeX,
              top: safeY,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  // Gentle vertical bob: -3px to +3px, paused while dragging
                  final double bobOffset = _isDragging 
                      ? 0.0 
                      : math.sin(_floatController.value * math.pi) * 3.0;
                  // Subtle glow pulse: shadow opacity oscillates
                  final double glowPulse = _isDragging
                      ? 0.0
                      : 0.15 + (math.sin(_floatController.value * math.pi) * 0.1);
                  
                  return Transform.translate(
                    offset: Offset(0, bobOffset),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: (details) {
                          if (_isDragging) {
                          double finalX = _position.dx.clamp(16.0, parentWidth - 70.0 - 16.0);
                          double finalY = _position.dy.clamp(60.0, parentHeight - 70.0 - 50.0);
                          
                          if (finalX + 35 < parentWidth/2) {
                             finalX = 16.0;
                          } else {
                             finalX = parentWidth - 70.0 - 16.0;
                          }

                          setState(() {
                            _isDragging = false;
                            _position = Offset(finalX, finalY);
                          });
                           _savePosition();
                          }
                      },
                      onTap: () {
                         if (!_isDragging) {
                            widget.onTap();
                         }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isDragging ? 70 : ((_showPreview || (!isChat && widget.unreadCount > 0)) ? 220 : 60), 
                        height: _isDragging ? 70 : 60,
                        curve: Curves.easeOutBack,
                        decoration: BoxDecoration(
                          color: _isDragging ? bgColor.withValues(alpha: 0.95) : bgColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isDragging ? 0.4 : 0.2),
                              blurRadius: _isDragging ? 16 : 8,
                              offset: Offset(0, _isDragging ? 8 : 4),
                            ),
                            // Glow pulse shadow (colored)
                            if (!_isDragging)
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: glowPulse),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Stack(
                          children: [
                             // Content
                             Center(
                               child: isChat 
                               ? Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: const [
                                     Icon(Icons.sports_esports, color: Colors.white, size: 28),
                                     Text("보드", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                   ],
                                 )
                                : ((_showPreview || widget.unreadCount > 0) 
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Row(
                                        children: [
                                           Icon(Icons.chat_bubble, color: Colors.white.withValues(alpha: 0.9), size: 24),
                                           const SizedBox(width: 8),
                                           Expanded(
                                             child: Text(
                                               widget.latestMessage ?? "", 
                                               style: const TextStyle(color: Colors.white, fontSize: 11),
                                               maxLines: 2,
                                               overflow: TextOverflow.ellipsis
                                             ),
                                           )
                                        ],
                                      ),
                                    )
                                  : const Icon(Icons.chat_bubble, color: Colors.white, size: 30)
                                 )
                             ),
                             
                             // Badge
                             if (!isChat && widget.unreadCount > 0)
                               Positioned(
                                 right: 0,
                                 top: 0,
                                 child: IgnorePointer(
                                   child: Container(
                                     padding: const EdgeInsets.all(6),
                                     decoration: const BoxDecoration(
                                       color: Colors.red,
                                       shape: BoxShape.circle,
                                     ),
                                     constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                     child: Center(
                                       child: Text(
                                         "${widget.unreadCount}",
                                         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                       ),
                                     ),
                                   ).animate(key: ValueKey(widget.unreadCount)).scale(duration: 300.ms, curve: Curves.elasticOut),
                                 ),
                               ),
                          ],
                        ),
                      )
                      .animate(target: (widget.unreadCount > 0 && !isChat) ? 1 : 0)
                      .shake(delay: 500.ms, hz: 4, curve: Curves.easeInOut), // Shake if unread
                    ),
                  );
                },
              ),
            ),
          ]
        );
      }
    );
  }
}
