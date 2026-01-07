import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/games/physics/game_engine.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PenaltyKickGame extends StatefulWidget {
  final VoidCallback onWin; 
  final VoidCallback onClose;

  const PenaltyKickGame({
    super.key,
    required this.onWin,
    required this.onClose,
  });

  @override
  State<PenaltyKickGame> createState() => _PenaltyKickGameState();
}

class _PenaltyKickGameState extends State<PenaltyKickGame> with TickerProviderStateMixin {
  late Ticker _ticker;
  final GameSession _session = GameSession();
  StreamSubscription? _eventSub;
  
  // Animation
  late AnimationController _goalieShakeController;
  late Animation<double> _goalieShakeAnimation;
  
  // Entities
  late GameEntity _ball;
  late GameEntity _goalie;
  
  // Sync Smoothing
  double? _remoteGoalieTargetX;
  
  // State
  int _score = 0;
  bool _shotTaken = false;
  bool _isBlocked = false;
  
  // Round Logic
  double _timeLeft = 15.0;
  bool _isRoundActive = false;
  bool _isRoundOver = false;
  
  // Overlay State
  bool _showRoundOverlay = false;
  int _lastKnownRound = 0;
  
  // Sync
  DateTime _lastSync = DateTime.now();

  double _lastTime = 0;
  Size _gameSize = Size.zero;
  
  // Drag Input
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionUpdate);
    _eventSub = _session.gameEvents.listen(_onGameEvent);
    
    // Shake Animation
    _goalieShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _goalieShakeAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _goalieShakeController, curve: Curves.elasticIn)
    );
    
    _resetGame();
    _ticker = createTicker(_onTick)..start();
    _checkRoundState();
  }

  void _onSessionUpdate() {
    if (!mounted) return;
    // Widget relies on GameScreen to unmount it if interactionState is null.
    // Do NOT call widget.onClose() here, as it triggers resolveInteraction() which might be too late.
    if (_session.interactionState != null) {
      _checkRoundState();
    }
    setState(() {});
  }
  
  bool _isWaitingForStart = true;

  void _checkRoundState() {
    final state = _session.interactionState;
    if (state == null) return;

    final round = state['round'] ?? 1;
    
    // Detect Round Change
    if (round != _lastKnownRound) {
       _lastKnownRound = round;
       
       // Force Reset Logic for new Round
       _resetGame(); 
       
       // Set Waiting State (Don't auto start)
       _isWaitingForStart = true;
       _isRoundActive = false;
       _showRoundOverlay = true; // Show "Round X" then transition to Start Button

       if (state['step'] != 'finished') {
          Future.delayed(const Duration(seconds: 2), () {
             if (mounted) setState(() => _showRoundOverlay = false);
          });
       }
    }
  }

  void _startRoundManually() {
     _isWaitingForStart = false; 
     _isRoundActive = true;
     _resetGame();
     _session.sendGameEvent({'eventType': 'round_start'});
     setState(() {});
  }
  
  void _onGameEvent(Map<String, dynamic> payload) {
     if (_gameSize == Size.zero) return;

     final activePlayer = _session.interactionState?['activePlayer'];
     final myRole = _session.myRole;
     
     final isKicker = (activePlayer == myRole);

     if (payload['eventType'] == 'round_start') {
        // Spectator receives start signal
        if (!isKicker) {
           _isWaitingForStart = false;
           _isRoundActive = true;
           setState(() {});
        }
     } else if (payload['eventType'] == 'goalie_move') {
        // If I am Spectator (Defender), I observe Goalie
        if (!isKicker) {
           double normX = (payload['x'] as num).toDouble();
           // Map normX to goal area
           double goalLeft = 20;
           double goalRight = _gameSize.width - 20;
           double range = goalRight - goalLeft - _goalie.width;
           double targetX = goalLeft + (normX * range);
                      double normVX = (payload.containsKey('vx')) ? (payload['vx'] as num).toDouble() : 0.0;

            _remoteGoalieTargetX = targetX;
            // Smooth Correction
            if ((_goalie.x - targetX).abs() > 50) {
               _goalie.x = targetX; 
            } else {
               _goalie.x = _goalie.x * 0.8 + targetX * 0.2;
            }
            
            _goalie.vx = normVX * _gameSize.width;
         }
     } else if (payload['eventType'] == 'shot') {
        // If I am Goalie, I observe Shot
        if (!isKicker) {
           _shotTaken = true;
           double normVX = (payload['vx'] as num).toDouble();
           double normVY = (payload['vy'] as num).toDouble();
           
           _ball.vx = normVX * _gameSize.width;
           _ball.vy = normVY * _gameSize.height;
           
           // If I am viewing inverted (Goalie), do I need to invert Shot Vector?
           // Shot is in World Coordinates.
           // Transform.rotate handles rendering.
           // Physics Update handles World Coords.
           // So NO inversion needed for Physics state.
           // Visuals will rotate the world, so Ball moving +Y (Down in World)
           // will look like moving Up on Rotated Screen?
           // Wait. +Y is Down. Kicker shoots Up (-Y).
           // Ball moves -Y (0).
           // Rotated Screen (Pi):
           // World 0,0 is Bottom-Right of Screen?
           // Rotation is around Center.
           // If Center is Pivot.
           // Top-Left (-W/2, -H/2) -> Bottom-Right.
           // Ball moving Up (-Y) in World.
           // On Rotated Screen: Moving Down (+Y visually relative to screen top).
           // Goalie sees ball coming AT them (Downwards). Correct.
        }
     }
  }



  void _resetGame() {
    _score = 0;
    _shotTaken = false;
    _isRoundOver = false;
    _timeLeft = 15.0;
    _dragStart = null;
    _dragCurrent = null;
    _remoteGoalieTargetX = null;
    
    _ball = GameEntity(x: 0, y: 0, width: 80, height: 80, color: Colors.white);
    _goalie = GameEntity(x: 0, y: 0, width: 160, height: 120, color: Colors.blueAccent);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionUpdate);
    _eventSub?.cancel();
    _ticker.dispose();
    _goalieShakeController.dispose();
    super.dispose();
  }
  
  void _onTick(Duration elapsed) {
    if (!_isRoundActive || _isRoundOver) return;

    final double currentTime = elapsed.inMicroseconds / 1000000.0;
    double dt = currentTime - _lastTime;
    if (_lastTime == 0) dt = 0.016;
    _lastTime = currentTime;
    
    if (_gameSize == Size.zero) return;
    
    // Timer (Controlled by Kicker)
    // If I am Goalie, I just follow state or loose sync timer?
    // Let's rely on Session Round Change for tight sync, or just run timer locally.
    // Local timer OK for 15s.
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
       _timeLeft = 0;
       
       // Only Kicker submits
       final activePlayer = _session.interactionState?['activePlayer'];
       if (activePlayer == _session.myRole) {
          _finishRound();
       }
       return;
    }

    _updateGame(dt);
    setState(() {});
  }
  
  Future<void> _finishRound() async {
    _isRoundActive = false;
    _isRoundOver = true;
    setState(() {});
    await _session.submitMiniGameScore(_score);
  }

  void _updateGame(double dt) {
       final activePlayer = _session.interactionState?['activePlayer'];
       final isKicker = activePlayer == _session.myRole;

       // 1. Update Goalie
       if (isKicker) {
           // I am Kicker (Active Player) -> I Run Goalie AI
           // Simple Sine Wave AI
           double time = _timeLeft; // use time left as phase
           double speed = 200.0;
           double amplitude = (_gameSize.width - 40) / 2;
           double centerX = _gameSize.width / 2 - _goalie.width/2;
           
           // x = center + sin(time * speed) * amplitude
           // Actually, let's make it simpler.
           // Just oscillate left-right.
           
           _goalie.x += _goalie.vx * dt;
           if (_goalie.x <= 20) {
              _goalie.x = 20;
              _goalie.vx = speed.abs();
           } else if (_goalie.x >= _gameSize.width - 20 - _goalie.width) {
              _goalie.x = _gameSize.width - 20 - _goalie.width;
              _goalie.vx = -speed.abs();
           }
           if (_goalie.vx == 0) _goalie.vx = speed; // Kickstart

           // Sync Goalie Pos to Spectator
           if (DateTime.now().difference(_lastSync).inMilliseconds > 50) {
               double range = (_gameSize.width - 40 - _goalie.width);
               double normX = (_goalie.x - 20) / range;
               // We send Ball Pos too to assist visualization if needed, but Ball is mostly event driven (Shot)
               // Sending Goalie X is enough for smooth blocking vis.
               double vxNorm = _goalie.vx / _gameSize.width; // Normalize Velocity
               _session.sendGameEvent({'eventType': 'goalie_move', 'x': normX, 'vx': vxNorm});
               _lastSync = DateTime.now();
           }

       } else {
           // I am Spectator -> Predict Goalie Movement
           _goalie.x += _goalie.vx * dt;
           
           // Simple Bounce Prediction
           if (_goalie.x <= 20) {
               _goalie.x = 20;
               _goalie.vx = _goalie.vx.abs();
           } else if (_goalie.x >= _gameSize.width - 20 - _goalie.width) {
               _goalie.x = _gameSize.width - 20 - _goalie.width;
               _goalie.vx = -_goalie.vx.abs();
           }
       }

       // 2. Update Ball
       if (_shotTaken) {
          _ball.update(dt);
          _ball.vx *= 0.99;
          _ball.vy *= 0.99;
          
          if (isKicker) {
              // Collision logic only for Kicker (Authoritative)
              
              final double zoneHeight = _gameSize.height / 3;
              
              // 1. HITBOX: Center-based & Shrunk (Visual Body Only)
              Rect goalieRect = Rect.fromCenter(
                 center: Offset(
                    _goalie.x + _goalie.width / 2, 
                    _goalie.y + _goalie.height / 2 + 10 // Shift down slightly to cover body/legs
                 ), 
                 width: _goalie.width * 0.5, // 50% width
                 height: _goalie.height * 0.6 // 60% height
              );
              
              // 2. BALL: Circular Collision
              final double ballRadius = _ball.width / 2 * 0.8; // 80% visual size for forgiving hit
              final Offset ballCenter = Offset(_ball.x + _ball.width/2, _ball.y + _ball.height/2);

              if (goalieRect.inflate(ballRadius).contains(ballCenter)) {
                 if (!_isBlocked) { // Only trigger once
                     _isBlocked = true;
                     // Trigger Goalie Shake
                     _goalieShakeController.forward(from: 0);
                     
                     // BOUNCE OFF
                     _ball.vy = -_ball.vy * 0.6; // Bounce back
                     _ball.vx = _ball.vx * 0.8 + (_goalie.vx * 0.5); 
                     
                     // Push ball out just enough to prevent sticking
                     // Simple push: if roughly above/below, push Y. If side, push X?
                     // For PK, mostly pushing DOWN/OUT is enough.
                     if (ballCenter.dy < goalieRect.center.dy) {
                        // Hit top head?
                        _ball.y = goalieRect.top - _ball.height - 2;
                     } else {
                        // Body hit, push down
                        _ball.y = goalieRect.bottom + 2;
                     }
                 }
              }
              
              // 1. FAIL/SAVE CONDITION
              // If blocked and bounced back "10pt" (we use 10px relative to goalie bottom)
              // User said: "If hits goalie and bounces 10pt -> Save -> Reset"
              if (_isBlocked) {
                  if (_ball.y > (_goalie.y + _goalie.height) + 10) {
                     // Saved!
                     Future.delayed(const Duration(milliseconds: 200), _resetBall);
                  }
              }
              
              // 3. GOAL CONDITION: Dynamic & Forgiving
              // If NOT hits goalie and reaches deep into goal (e.g. top 10% of zone)
              final double goalLineY = zoneHeight * 0.1;
              
              if (!_isBlocked && _ball.y < goalLineY) { 
                 _score++;
                 // Force goal sound or effect here if needed
                 _resetBall();
              }
              
              // Wall Bounce
              if (_ball.x <= 0) {
                 _ball.x = 0;
                 _ball.vx = -_ball.vx; // Bounce Right
              } else if (_ball.x + _ball.width >= _gameSize.width) {
                 _ball.x = _gameSize.width - _ball.width;
                 _ball.vx = -_ball.vx; // Bounce Left
              }
              
              // Fallback Reset (Out of Bounds)
              if (_ball.y > _gameSize.height) {
                 _resetBall();
              }
          } else {
             // Spectator JUST visualizes balls.
             // If out of bounds/goal -> Reset
             if (_ball.y < 0 || _ball.y > _gameSize.height) {
                Future.delayed(const Duration(milliseconds: 500), _resetBall);
             }
          }
       } else {
         if (_ball.vx == 0 && _ball.y == 0) {
            _ball.x = _gameSize.width / 2 - _ball.width / 2;
            _ball.y = _gameSize.height - 120;
         }
       }
  }
  
  void _resetBall() {
      _shotTaken = false;
      _isBlocked = false;
      _ball.x = _gameSize.width / 2 - _ball.width / 2;
      _ball.y = _gameSize.height - 120;
      _ball.vx = 0;
      _ball.vy = 0;
      _dragStart = null;
      _dragCurrent = null;
  }
  
  bool _isDraggingBall = false;

  void _onPanStart(DragStartDetails details) {
    // Determine context: Active Player ONLY
    final activePlayer = _session.interactionState?['activePlayer'];
    final isKicker = activePlayer == _session.myRole;
    
    // SPECTATOR CANNOT INTERACT
    if (!isKicker) return;

    if (_shotTaken) return;
    
    final ballRect = Rect.fromLTWH(_ball.x, _ball.y, _ball.width, _ball.height);
    final touchRect = ballRect.inflate(20);
    
    if (touchRect.contains(details.localPosition)) {
       setState(() {
         _isDraggingBall = true;
         _dragStart = details.localPosition; 
         _dragCurrent = details.localPosition;
       });
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    final activePlayer = _session.interactionState?['activePlayer'];
    final isKicker = activePlayer == _session.myRole;

    if (!isKicker) return; // Spectator Ignore
    if (_shotTaken) return;
    
    if (_isDraggingBall) {
       setState(() {
          _dragCurrent = details.localPosition;
       });
    }
  }
  
  void _onPanEnd(DragEndDetails details) {
     final activePlayer = _session.interactionState?['activePlayer'];
     final isKicker = activePlayer == _session.myRole;
     
     if (!isKicker) return;
     if (_shotTaken) return;
     
     if (_isDraggingBall) {
        _isDraggingBall = false;
        _dragStart = null; 
        _dragCurrent = null;

        // Analyze Flick Velocity
        double vx = details.velocity.pixelsPerSecond.dx;
        double vy = details.velocity.pixelsPerSecond.dy;
        
        if (vy < -200) { 
           _shotTaken = true;
           double powerFactor = 0.55; 
           
           _ball.vx = vx * powerFactor;
           _ball.vy = vy * powerFactor;
           
           double speed = sqrt(_ball.vx*_ball.vx + _ball.vy*_ball.vy);
           if (speed > 1600) {
              double ratio = 1600 / speed;
              _ball.vx *= ratio;
              _ball.vy *= ratio;
           }

            // Synch Shot to Spectator (Normalized)
           if (_gameSize.width > 0 && _gameSize.height > 0) {
              _session.sendGameEvent({
                 'eventType': 'shot', 
                 'vx': _ball.vx / _gameSize.width, 
                 'vy': _ball.vy / _gameSize.height
              });
           }
           
           setState(() {}); 
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final state = _session.interactionState;
    if (state == null) return const SizedBox();

    final activePlayer = state['activePlayer'];
    final isKicker = activePlayer == _session.myRole;
    final round = state['round'] ?? 1;
    final scores = state['scores'] ?? {}; 

    // Keep Dark Theme for now but adapt shapes
    final colBg = const Color(0xFF0C0219);
    final colPrimary = const Color(0xFF6B14EC);
    final colText = const Color(0xFFFDF9FF);

    return Scaffold(
      backgroundColor: colBg, 
      body: SafeArea(
        child: Column(
          children: [
             // 1. HEADER (HUD)
             Container(
                height: 140,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                   color: colBg,
                   border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))
                ),
                child: Column(
                   children: [
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(
                                      isKicker ? "ATTACKER" : "GOALKEEPER",
                                      style: GoogleFonts.alexandria(color: Colors.grey, fontSize: 12),
                                   ),
                                   Text(
                                      isKicker ? "SCORE!" : "DEFEND!",
                                      style: GoogleFonts.alexandria(
                                         color: isKicker ? Colors.greenAccent : Colors.orangeAccent, 
                                         fontSize: 20, fontWeight: FontWeight.bold
                                      ),
                                   ),
                                ],
                             ),
                             
                             if (isKicker)
                               Text(
                                  "${_timeLeft.toStringAsFixed(1)}s", 
                                  style: GoogleFonts.alexandria(
                                     color: _timeLeft < 5 ? Colors.red : Colors.white, 
                                     fontSize: 32, fontWeight: FontWeight.bold
                                  ),
                               ),

                             Row(
                                children: [
                                   Icon(
                                      _session.isRealtimeConnected ? Icons.wifi : Icons.wifi_off, 
                                      color: _session.isRealtimeConnected ? Colors.greenAccent : Colors.red, 
                                      size: 16
                                   ),
                                   const SizedBox(width: 10),
                                   IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      onPressed: widget.onClose,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                   ),
                                ],
                             )
                          ],
                       ),
                       const Spacer(),
                       // Scoreboard
                       Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             _buildScoreBadge("YOU", isKicker ? _score : (scores[_session.myRole] ?? 0), isKicker),
                             const SizedBox(width: 20),
                             Text("-", style: GoogleFonts.alexandria(color: Colors.white30, fontSize: 20)),
                             const SizedBox(width: 20),
                             _buildScoreBadge("OPPONENT", scores[isKicker ? (_session.myRole == 'A' ? 'B' : 'A') : activePlayer] ?? 0, !isKicker),
                          ],
                       ),
                   ],
                ),
             ),

             // 2. GAME AREA
             Expanded(
                child: Padding(
                   padding: const EdgeInsets.all(10.0),
                   child: LayoutBuilder(
                      builder: (context, constraints) {
                         // Update Game Size
                         if (_gameSize.width != constraints.maxWidth || _gameSize.height != constraints.maxHeight) {
                            _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
                            
                            // Recalculate Logic based on new size
                            final double zoneHeight = _gameSize.height / 3;

                            // Kicker Ball Pos: Bottom Zone Center
                            _ball.x = _gameSize.width / 2 - _ball.width / 2;
                            _ball.y = zoneHeight * 2 + (zoneHeight / 2) - (_ball.height / 2); 
                            
                            // Goalie Pos: Top Zone (Goal)
                            _goalie.x = _gameSize.width / 2 - _goalie.width / 2;
                            _goalie.y = (zoneHeight / 2) - (_goalie.height / 2); // Center of Top Zone
                         }
                         
                         final double zoneHeight = _gameSize.height / 3;

                         return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                               border: Border.all(color: Colors.white, width: 4),
                               color: Colors.white, 
                            ),
                            child: ClipRect(
                               child: Stack(
                                  children: [
                                     
                                     // 1. INPUT LAYER
                                     GestureDetector(
                                        onPanStart: _onPanStart,
                                        onPanUpdate: _onPanUpdate,
                                        onPanEnd: _onPanEnd,
                                        child: Container(
                                           width: double.infinity, 
                                           height: double.infinity,
                                           color: Colors.transparent,
                                           child: Stack(
                                              children: [
                                                 // A. Background Painter
                                                 Positioned.fill(
                                                    child: Transform.rotate(
                                                       angle: isKicker ? 0 : pi,
                                                       child: CustomPaint(
                                                          painter: _SoccerPainter(
                                                             dragStart: _dragStart,
                                                             dragCurrent: _dragCurrent,
                                                             colPrimary: colPrimary,
                                                             colText: colText,
                                                             zoneHeight: zoneHeight,
                                                             ballCenter: Offset(_ball.x + _ball.width/2, _ball.y + _ball.height/2),
                                                          ),
                                                       )
                                                    )
                                                 ),
                                              ]
                                           ),
                                        ),
                                     ),

                                     // 2. ENTITIES (Rotated)
                                     IgnorePointer(
                                        child: Transform.rotate(
                                           angle: isKicker ? 0 : pi,
                                           child: Stack(
                                              children: [
                                                 // Goalie
                                                 Positioned(
                                                    left: _goalie.x, top: _goalie.y,
                                                    width: _goalie.width, height: _goalie.height,
                                                    child: AnimatedBuilder(
                                                       animation: _goalieShakeAnimation,
                                                       builder: (context, child) {
                                                           // Shake horizontally
                                                           double dx = sin(_goalieShakeAnimation.value * pi * 3) * 5;
                                                           return Transform.translate(
                                                              offset: Offset(dx, 0),
                                                              child: child
                                                           );
                                                       },
                                                       child: SvgPicture.asset('assets/images/Goalkeeper.svg'),
                                                    ),
                                                 ),
                                                 // Ball
                                                 Positioned(
                                                    left: _ball.x, top: _ball.y,
                                                    width: _ball.width, height: _ball.height,
                                                    child: SvgPicture.asset('assets/images/soccerball.svg'),
                                                 ),
                                              ],
                                           ),
                                        ),
                                     ),

                                     // OVERLAYS (Centered in Game Box)
                                     
                                     // MANUAL START
                                     if (_isWaitingForStart && !_showRoundOverlay && state['step'] != 'finished')
                                        Container(
                                           color: Colors.black.withOpacity(0.8),
                                           alignment: Alignment.center,
                                           child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                 Text(
                                                    isKicker ? "YOU ARE KICKER" : "SPECTATOR MODE",
                                                    style: GoogleFonts.alexandria(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)
                                                 ),
                                                 const SizedBox(height: 20),
                                                 if (isKicker)
                                                   ElevatedButton.icon(
                                                      onPressed: _startRoundManually,
                                                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                      label: Text("START GAME", style: GoogleFonts.alexandria(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                      style: ElevatedButton.styleFrom(
                                                         backgroundColor: colPrimary,
                                                         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      ),
                                                   )
                                                 else
                                                   Column(
                                                     children: [
                                                        const CircularProgressIndicator(color: Colors.white),
                                                        const SizedBox(height: 20),
                                                        Text("Waiting for Kicker...", style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 16)),
                                                     ],
                                                   )
                                              ],
                                           ),
                                        ),

                                     // ROUND CHANGE
                                     if (_showRoundOverlay)
                                        Container(
                                           color: Colors.black.withOpacity(0.8),
                                           alignment: Alignment.center,
                                           child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                 Text(
                                                    "ROUND $round", 
                                                    style: GoogleFonts.alexandria(color: colPrimary, fontSize: 30, fontWeight: FontWeight.bold)
                                                 ),
                                                 const SizedBox(height: 10),
                                                 Text(
                                                    isKicker ? "ATTACK!" : "DEFEND!", 
                                                    style: GoogleFonts.alexandria(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
                                                 ),
                                              ],
                                           ),
                                        ),

                                  ],
                               ) 
                            ),
                         );
                      }
                   ),
                ),
             )
          ],
        ),
      ),
      // GLOBAL OVERLAYS (Covering Header too)
      bottomSheet: (state != null && state['step'] == 'finished') ? Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.95),
          alignment: Alignment.center,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                Text(
                   (state['winner'] == _session.myRole) ? "VICTORY!" : (state['winner'] == null ? "DRAW!" : "DEFEAT!"), 
                   style: GoogleFonts.alexandria(
                      color: (state['winner'] == _session.myRole) ? Colors.greenAccent : Colors.redAccent, 
                      fontSize: 50, fontWeight: FontWeight.bold
                   )
                ),
                const SizedBox(height: 30),
                Text(
                   "FINAL SCORE",
                   style: GoogleFonts.alexandria(color: Colors.white54, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      _buildBigScore("YOU", isKicker ? _score : (scores[_session.myRole] ?? 0), isKicker),
                      const SizedBox(width: 40),
                      Text("VS", style: GoogleFonts.alexandria(color: Colors.white24, fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 40),
                      _buildBigScore("OPPONENT", scores[isKicker ? (_session.myRole == 'A' ? 'B' : 'A') : activePlayer] ?? 0, !isKicker),
                   ],
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                       backgroundColor: colPrimary, 
                       padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                    onPressed: () {
                       _session.closeMiniGame();
                    },
                    child: Text("CLOSE GAME", style: GoogleFonts.alexandria(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
             ],
          ),
      ) : null,
    );
  }

  Widget _buildBigScore(String label, int score, bool isWin) {
     return Column(
        children: [
           Text(label, style: GoogleFonts.alexandria(color: Colors.white, fontSize: 16)),
           const SizedBox(height: 10),
           Text("$score", style: GoogleFonts.alexandria(color: isWin ? Colors.greenAccent : Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
        ],
     );
  }

  Widget _buildScoreBadge(String label, int score, bool isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
           color: isActive ? Color(0xFF6B14EC).withOpacity(0.8) : Colors.grey.withOpacity(0.2),
           borderRadius: BorderRadius.circular(8),
           border: isActive ? Border.all(color: Colors.white30) : null
        ),
        child: Column(
           children: [
              Text(label, style: GoogleFonts.alexandria(color: Colors.white60, fontSize: 10)),
              Text("$score", style: GoogleFonts.alexandria(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
           ],
        ),
      );
  }

  }


class _SoccerPainter extends CustomPainter {
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Color colPrimary;
  final Color colText;
  final double zoneHeight;
  final Offset ballCenter;
  
  _SoccerPainter({
    required this.dragStart, 
    required this.dragCurrent,
    required this.colPrimary,
    required this.colText,
    required this.zoneHeight,
    required this.ballCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
     // Zones
     // Top: Goal Area
     // Middle: Field (Empty/Black)
     // Bottom: Kick Zone
     
     final double w = size.width;
     
     // 1. Kick Zone Background (Bottom 1/3)
     final paintKickZone = Paint()..color = colPrimary.withOpacity(0.15)..style = PaintingStyle.fill;
     canvas.drawRect(Rect.fromLTWH(0, zoneHeight * 2, w, zoneHeight), paintKickZone);
     
     // 2. Goal Net Visuals (Top 1/3)
     // Grid
     final paintGrid = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 1;
     double gridSize = 20.0;
     for (double i = 0; i < w; i += gridSize) {
        canvas.drawLine(Offset(i, 0), Offset(i, zoneHeight), paintGrid);
     }
     for (double i = 0; i < zoneHeight; i += gridSize) {
        canvas.drawLine(Offset(0, i), Offset(w, i), paintGrid);
     }
     
     // Goal Frame (Thick White/Primary)
     final paintFrame = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4;
     canvas.drawRect(Rect.fromLTWH(0, 0, w, zoneHeight), paintFrame);

     // 3. Drag Arrow (Only dynamic part drawn by painter)
     if (dragStart != null && dragCurrent != null) {
        final Offset start = ballCenter; 
        final dx = dragCurrent!.dx - dragStart!.dx;
        final dy = dragCurrent!.dy - dragStart!.dy;
        double len = sqrt(dx*dx + dy*dy);
        double maxLen = 100.0;
        double scale = 1.0;
        if (len > maxLen) scale = maxLen / len;
        
        final end = start + Offset(dx*scale, dy*scale);
        final paintArrow = Paint()..color = Colors.white.withOpacity(0.6)..strokeWidth = 4..strokeCap = StrokeCap.round;
        // Draw Drag Line
        canvas.drawLine(start, end, paintArrow);
        
        // Draw Arrowhead
        double angle = atan2(dy, dx);
        double arrowHeadLen = 15.0;
        final p1 = end - Offset(cos(angle - pi/6)*arrowHeadLen, sin(angle - pi/6)*arrowHeadLen);
        final p2 = end - Offset(cos(angle + pi/6)*arrowHeadLen, sin(angle + pi/6)*arrowHeadLen);
        canvas.drawLine(end, p1, paintArrow);
        canvas.drawLine(end, p2, paintArrow);
     }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
