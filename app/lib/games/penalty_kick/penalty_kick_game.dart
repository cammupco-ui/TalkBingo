import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/games/physics/game_engine.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform

// New Imports
import 'package:talkbingo_app/games/config/penalty_kick_config.dart';
import 'package:talkbingo_app/games/config/responsive_config.dart';
import 'package:talkbingo_app/widgets/game_header.dart';
import 'package:talkbingo_app/widgets/power_gauge.dart';
import 'package:talkbingo_app/widgets/mini_game_coach_overlay.dart';
import 'package:talkbingo_app/services/onboarding_service.dart';

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
  
  // Platform & Responsive Config
  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  // Config (Initialized in build/LayoutBuilder)
  PenaltyKickConfig? _config;

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
  DateTime _lastTimeSync = DateTime.now(); // For timer sync
  int _remoteScore = 0; // Spectator tracks opponent score

  double _lastTime = 0;
  Size _gameSize = Size.zero;
  
  // Drag Input
  Offset? _dragStart;
  Offset? _dragCurrent;
  
  // Power Gauge State
  double _currentPower = 0.0;
  String _powerLabel = '';
  
  // Visual Effects
  double _goalFlash = 0.0;
  double _ballRotation = 0.0;
  bool _showCoachOverlay = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionUpdate);
    _eventSub = _session.gameEvents.listen(_onGameEvent);
    
    // Check coach mark
    OnboardingService.shouldShowCoachMark('mini_penalty').then((show) {
      if (show && mounted) setState(() => _showCoachOverlay = true);
    });
    
    // Shake Animation
    _goalieShakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _goalieShakeAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _goalieShakeController, curve: Curves.elasticIn)
    );
    
    _resetGame();
    _ticker = createTicker(_onTick)..start();
    _checkRoundState();
  }

  void _updateConfig(Size size) {
     if (_config?.screenSize != size) {
        _config = PenaltyKickConfig(size, isGameArea: true);
     }
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
  bool _isPaused = false; // Mini-game pause

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
           _timeLeft = 15.0; // Full time
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
      } else if (payload['eventType'] == 'score_update') {
         // Real-time Score Sync
         if (payload.containsKey('score')) {
            setState(() {
               if (!isKicker) {
                  _remoteScore = (payload['score'] as num).toInt();
               }
            });
         }
      } else if (payload['eventType'] == 'time_sync') {
         if (!isKicker && payload.containsKey('time')) {
            double serverTime = (payload['time'] as num).toDouble();
            if ((_timeLeft - serverTime).abs() > 2.0) {
               _timeLeft = serverTime;
            }
         }
      } else if (payload['eventType'] == 'ball_save') {
         if (!isKicker) {
            setState(() {
               _isBlocked = true;
               _ball.x = (payload['bx'] as num).toDouble() * _gameSize.width;
               _ball.y = (payload['by'] as num).toDouble() * _gameSize.height;
               _ball.vx = (payload['bvx'] as num).toDouble() * _gameSize.width;
               _ball.vy = (payload['bvy'] as num).toDouble() * _gameSize.height;
               _goalieShakeController.forward(from: 0);
            });
         }
      } else if (payload['eventType'] == 'ball_goal') {
         if (!isKicker) {
            setState(() {
               _goalFlash = 1.0;
               _resetBall();
            });
         }
      } else if (payload['eventType'] == 'ball_reset') {
         if (!isKicker) {
            setState(() => _resetBall());
         }
      } else if (payload['eventType'] == 'game_pause') {
         setState(() => _isPaused = true);
      } else if (payload['eventType'] == 'game_resume') {
         setState(() => _isPaused = false);
      }
   }



  void _resetGame() {
    _score = 0;
    _shotTaken = false;
    _isBlocked = false;
    _isRoundOver = false;
    _timeLeft = 15.0;
    _dragStart = null;
    _dragCurrent = null;
    _remoteGoalieTargetX = null;
    _remoteScore = 0;
    _goalFlash = 0.0;
    _ballRotation = 0.0;
    
    // Initial sizes 0, will be set in LayoutBuilder
    _ball = GameEntity(x: 0, y: 0, width: 0, height: 0, color: Colors.white);
    _goalie = GameEntity(x: 0, y: 0, width: 0, height: 0, color: Colors.blueAccent);
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
    if (!_isRoundActive || _isRoundOver || _isPaused) {
      _lastTime = 0; // Reset so resume doesn't jump the timer
      return;
    }

    final double currentTime = elapsed.inMicroseconds / 1000000.0;
    double dt = currentTime - _lastTime;
    if (_lastTime == 0) dt = 0.016;
    _lastTime = currentTime;
    
    if (_gameSize == Size.zero) return;
    
    // Timer (Controlled by Kicker)
    final activePlayer = _session.interactionState?['activePlayer'];
    final isKicker = activePlayer == _session.myRole;

    if (isKicker) {
       _timeLeft -= dt;
       
       // Sync Time
       if (DateTime.now().difference(_lastTimeSync).inSeconds >= 2) {
           _session.sendGameEvent({'eventType': 'time_sync', 'time': _timeLeft});
           _lastTimeSync = DateTime.now();
       }

       if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finishRound();
          return;
       }
    } else {
       // Spectator follow
       _timeLeft -= dt;
       if (_timeLeft < 0) _timeLeft = 0;
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
          _ball.vx *= 0.995;
          _ball.vy *= 0.995;
          
          if (isKicker) {
              // Collision logic only for Kicker (Authoritative)
              
              final double zoneHeight = _gameSize.height / 3;
              
              // 1. HITBOX: Center-based & Shrunk (Visual Body Only)
              Rect goalieRect = Rect.fromCenter(
                  center: Offset(
                     _goalie.x + _goalie.width / 2, 
                     _goalie.y + _goalie.height / 2 
                  ), 
                  width: _goalie.width * 0.9, // 90% width (Full Paddle)
                  height: _goalie.height * 0.8 // 80% height
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
                      
                      // Broadcast save to opponent
                      _session.sendGameEvent({
                        'eventType': 'ball_save',
                        'bx': _ball.x / _gameSize.width,
                        'by': _ball.y / _gameSize.height,
                        'bvx': _ball.vx / _gameSize.width,
                        'bvy': _ball.vy / _gameSize.height,
                      });
                     }
                 }
              }
              
              // 1. FAIL/SAVE CONDITION
              // If blocked and bounced back "10pt" (we use 10px relative to goalie bottom)
              // User said: "If hits goalie and bounces 10pt -> Save -> Reset"
              if (_isBlocked) {
                  if (_ball.y > (_goalie.y + _goalie.height) + 10) {
                     // Saved! Tell opponent
                     _session.sendGameEvent({'eventType': 'ball_reset'});
                     Future.delayed(const Duration(milliseconds: 200), _resetBall);
                  }
              }
              
              // 3. GOAL CONDITION: Dynamic & Forgiving
              // If NOT hits goalie and reaches deep into goal (e.g. top 10% of zone)
              final double goalLineY = zoneHeight * 0.1;
                            if (!_isBlocked && _ball.y < goalLineY) { 
                  _score++;
                  _goalFlash = 1.0;
                  _session.sendGameEvent({'eventType': 'score_update', 'score': _score});
                  _session.sendGameEvent({'eventType': 'ball_goal'});
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
                 _session.sendGameEvent({'eventType': 'ball_reset'});
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
    final touchRect = ballRect.inflate(60);
    
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

    if (!isKicker) return; 
    if (_shotTaken) return;
    
    if (_isDraggingBall) {
       setState(() {
          _dragCurrent = details.localPosition;
          
          if (_dragStart != null) {
              final dx = _dragCurrent!.dx - _dragStart!.dx;
              final dy = _dragCurrent!.dy - _dragStart!.dy;
              final distance = sqrt(dx*dx + dy*dy);
              
              // Max Drag ~ 40% of Height (Config Driven)
              final maxDrag = (_config?.safeGameArea.height ?? 500) * 0.4;
              _currentPower = (distance / maxDrag).clamp(0.0, 1.2);
              _updatePowerFeedback();
          }
       });
    }
  }
  
  void _updatePowerFeedback() {
    String newLabel = '';
    if (_currentPower < 0.3) {
      newLabel = 'WEAK';
    } else if (_currentPower < 0.7) {
      newLabel = 'GOOD!';
    } else if (_currentPower < 1.0) {
      newLabel = 'STRONG';
    } else {
      newLabel = 'TOO STRONG!';
    }
    
    if (newLabel != _powerLabel) {
       _powerLabel = newLabel;
       if (newLabel == 'GOOD!') {
          HapticFeedback.mediumImpact();
       } else {
          HapticFeedback.selectionClick();
       }
    }
  }
  
    void _onPanEnd(DragEndDetails details) {
     final activePlayer = _session.interactionState?['activePlayer'];
     final isKicker = activePlayer == _session.myRole;
     
     if (!isKicker) return;
     if (_shotTaken) return;
     
     if (_isDraggingBall && _dragStart != null && _dragCurrent != null) {
        _isDraggingBall = false;
        
        // Use configured power/speed
        // Base Speed heavily influenced by Power Gauge
        final dx = _dragCurrent!.dx - _dragStart!.dx;
        final dy = _dragCurrent!.dy - _dragStart!.dy;
        
        // Cancel if too weak
        if (_currentPower < 0.15) {
             setState(() { _dragStart = null; _dragCurrent = null; _currentPower = 0; });
             return;
        }

        final angle = atan2(dy, dx);
        final baseSpeed = 1300.0; // Max reasonable speed
        
        _ball.vx = cos(angle) * baseSpeed * _currentPower;
        _ball.vy = sin(angle) * baseSpeed * _currentPower;
        
        // Random deviation if Overpowered (> 100%)
        if (_currentPower > 1.0) {
           _ball.vx += (Random().nextDouble() - 0.5) * 400;
        }

        _shotTaken = true;
         
        // Synch Shot
         if (_gameSize.width > 0 && _gameSize.height > 0) {
            _session.sendGameEvent({
               'eventType': 'shot', 
               'vx': _ball.vx / _gameSize.width, 
               'vy': _ball.vy / _gameSize.height
            });
         }
         
        setState(() {
           // Reset for UI but let physics run
           _dragStart = null; _dragCurrent = null; _currentPower = 0;
           _powerLabel = '';
        });
        
        HapticFeedback.heavyImpact();
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
    final colBg = const Color(0xFF0A2E14);
    final colPrimary = const Color(0xFF6B14EC);
    final colText = const Color(0xFFFDF9FF);

    // Config Update removed from here. Handled in LayoutBuilder
    // final size = MediaQuery.of(context).size;
    // if (_config == null || _config!.screenSize != size) {
    //    _updateConfig(size);
    // }

    return Scaffold(
      backgroundColor: const Color(0xFF0A2E14), 
      body: Stack(
         children: [
            Column(
              children: [
                 // 1. GAME HEADER
                 GameHeader(
                   gameTitle: "PENALTY KICK",
                   score: isKicker ? _score : _remoteScore,
                   opponentScore: isKicker ? _remoteScore : (scores[_session.myRole] ?? 0),
                   timeLeft: _timeLeft,
                   isMyTurn: isKicker,
                   onMenuTap: widget.onClose,
                 ),
                 
                 // 2. GAME AREA
                 Expanded(
                    child: Padding(
                       padding: const EdgeInsets.all(0), // Full width
                       child: LayoutBuilder(
                          builder: (context, constraints) {
                              if (_gameSize != constraints.biggest) {
                                  _gameSize = constraints.biggest;
                                  _updateConfig(_gameSize);
                              }
                              
                              // Check if config ready
                              if (_config == null) return const SizedBox();
                             
                             if (_config != null) {
                                // Update Entity Sizes from Config
                                _ball.width = _config!.ballSize;
                                _ball.height = _config!.ballSize;
                                _goalie.width = _config!.goalieWidth;
                                _goalie.height = _config!.goalieHeight;
                             }

                             final double zoneHeight = _gameSize.height / 3;

                             // Pos Logic (Only if not moving)
                             if (_ball.vx == 0 && _ball.vy == 0 && !_shotTaken && !_isDraggingBall) {
                                _ball.x = _gameSize.width / 2 - _ball.width / 2;
                                _ball.y = zoneHeight * 2 + (zoneHeight / 2) - (_ball.height / 2); 
                             }
                             if (_goalie.x == 0 && _config != null) {
                                 _goalie.x = _gameSize.width/2 - _goalie.width/2;
                             }
                             // Goalie Y
                             _goalie.y = (zoneHeight / 2) - (_goalie.height / 2); 

                             return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black,
                                child: ClipRect(
                                   child: Stack(
                                      children: [
                                         // 1. INPUT LAYER
                                         GestureDetector(
                                            onPanStart: _onPanStart,
                                            onPanUpdate: _onPanUpdate,
                                            onPanEnd: _onPanEnd,
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
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
                                                     // Power Gauge
                                                     if (_isDraggingBall)
                                                        Positioned(
                                                          left: 0, right: 0,
                                                          top: _ball.y - 100,
                                                          child: Center(
                                                            child: SizedBox(
                                                              width: 220,
                                                              child: PowerGauge(
                                                                power: _currentPower,
                                                                label: _powerLabel,
                                                                showLevels: true,
                                                              )
                                                            ),
                                                          ),
                                                        ),
                                                  ],
                                               ),
                                            ),
                                         ),

                                         // OVERLAYS

                                           // MANUAL START OVERLAY (pre-game)
                                           if (_isWaitingForStart && !_showRoundOverlay && state['step'] != 'finished')
                                             Positioned.fill(
                                               child: Container(
                                                 color: Colors.black.withOpacity(0.8),
                                                 alignment: Alignment.center,
                                                 child: Column(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     Text(
                                                       isKicker ? "YOU ARE KICKER" : "SPECTATOR MODE",
                                                       style: GoogleFonts.alexandria(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                                                     ),
                                                     const SizedBox(height: 20),
                                                      if (isKicker) ...[
                                                        // START + PAUSE — horizontal, same size
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            SizedBox(
                                                              width: 150,
                                                              height: 50,
                                                              child: ElevatedButton.icon(
                                                                onPressed: () {
                                                                  if (_isPaused) {
                                                                    setState(() => _isPaused = false);
                                                                    _session.sendGameEvent({'eventType': 'game_resume'});
                                                                  }
                                                                  _startRoundManually();
                                                                },
                                                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                                                label: Text("START", style: GoogleFonts.alexandria(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: AppColors.hostPrimary,
                                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            SizedBox(
                                                              width: 150,
                                                              height: 50,
                                                              child: ElevatedButton.icon(
                                                                onPressed: () {
                                                                  setState(() => _isPaused = !_isPaused);
                                                                  _session.sendGameEvent({'eventType': _isPaused ? 'game_pause' : 'game_resume'});
                                                                },
                                                                icon: Icon(_isPaused ? Icons.pause_circle : Icons.pause, color: _isPaused ? Colors.white : Colors.black87, size: 20),
                                                                label: Text(
                                                                  _isPaused ? "PAUSED" : "PAUSE",
                                                                  style: GoogleFonts.alexandria(color: _isPaused ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                                                                ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: _isPaused ? Colors.redAccent : Colors.amberAccent,
                                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ] else
                                                       Column(
                                                         children: [
                                                           const CircularProgressIndicator(color: Colors.white),
                                                           const SizedBox(height: 20),
                                                           Text("Waiting for Kicker...", style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 14)),
                                                         ],
                                                       ),
                                                   ],
                                                 ),
                                               ),
                                             ),

                                           // ROUND CHANGE OVERLAY
                                           if (_showRoundOverlay)
                                             Positioned.fill(
                                               child: Container(
                                                 color: Colors.black.withOpacity(0.8),
                                                 alignment: Alignment.center,
                                                 child: Column(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     Text(
                                                       "ROUND $round",
                                                       style: GoogleFonts.alexandria(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                                                     ),
                                                     const SizedBox(height: 10),
                                                     Text(
                                                       isKicker ? "KICK!" : "DEFEND!",
                                                       style: GoogleFonts.alexandria(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             ),
                                       ],   // outer Stack children (line 719)
                                    ),      // Stack (line 718)
                                 ),         // ClipRect (line 717)
                              );            // Container return (line 710)
                          }
                       ),
                    ),
                 )
              ],
            ),
            

          // ── Coach Mark Overlay ──
          if (_showCoachOverlay)
            Positioned.fill(
              child: MiniGameCoachOverlay(
                gameType: 'penalty',
                onClose: () {
                  setState(() => _showCoachOverlay = false);
                  if (_isWaitingForStart) _startRoundManually();
                },
              ),
            ),

         ]
      ),
      // GLOBAL OVERLAYS
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
  final double goalFlash;
  
  _SoccerPainter({
    required this.dragStart, 
    required this.dragCurrent,
    required this.colPrimary,
    required this.colText,
    required this.zoneHeight,
    required this.ballCenter,
    this.goalFlash = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
     final double w = size.width;
     final double h = size.height;
          // 1. BLACK BACKGROUND
      final bgPaint = Paint()..color = const Color(0xFF111111);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);
      
      // Subtle grid pattern
      final gridPaint2 = Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      for (double gx = 0; gx < w; gx += 40) {
         canvas.drawLine(Offset(gx, 0), Offset(gx, h), gridPaint2);
      }
      for (double gy = 0; gy < h; gy += 40) {
         canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint2);
      }
      
      // 2. ZONE SEPARATOR
      final zonePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, zoneHeight), Offset(w, zoneHeight), zonePaint);

      // 2b. SUBTLE FIELD MARKINGS (gray, semi-transparent — soccer identity)
      final fieldPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Center line (horizontal, in the kick zone area)
      final kickZoneCenter = zoneHeight + (h - zoneHeight) / 2;
      canvas.drawLine(Offset(0, kickZoneCenter), Offset(w, kickZoneCenter), fieldPaint);

      // Center circle
      final centerRadius = w * 0.15;
      canvas.drawCircle(Offset(w / 2, kickZoneCenter), centerRadius, fieldPaint);

      // Penalty area box (around the goal zone)
      final penaltyWidth = w * 0.6;
      final penaltyLeft = (w - penaltyWidth) / 2;
      final penaltyBottom = zoneHeight + (h - zoneHeight) * 0.25;
      canvas.drawRect(
        Rect.fromLTRB(penaltyLeft, 0, penaltyLeft + penaltyWidth, penaltyBottom),
        fieldPaint,
      );

      // Goal area box (smaller box inside penalty area)
      final goalAreaWidth = w * 0.35;
      final goalAreaLeft = (w - goalAreaWidth) / 2;
      final goalAreaBottom = zoneHeight * 0.7;
      canvas.drawRect(
        Rect.fromLTRB(goalAreaLeft, 0, goalAreaLeft + goalAreaWidth, goalAreaBottom),
        fieldPaint,
      );

      // Penalty arc (semicircle at bottom of penalty area)
      final arcPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final penaltySpot = Offset(w / 2, penaltyBottom + 20);
      canvas.drawArc(
        Rect.fromCenter(center: penaltySpot, width: centerRadius * 1.2, height: centerRadius * 1.2),
        3.14 * 0.2, // start angle
        3.14 * 0.6, // sweep angle (partial arc facing down)
        false,
        arcPaint,
      );

     // 3. GOAL NET (Perspective depth)
     // Net grid (slightly wider at top for perspective)
     final netPaint = Paint()
       ..color = Colors.white.withValues(alpha: 0.12)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 0.8;
     double gridSize = 16.0;
     
     // Vertical net lines
     for (double x = 0; x < w; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, zoneHeight * 0.9), netPaint);
     }
     // Horizontal net lines
     for (double y = 0; y < zoneHeight * 0.9; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(w, y), netPaint);
     }
     
     // Goal Frame (3D posts)
     final framePaint = Paint()
       ..color = Colors.white
       ..style = PaintingStyle.stroke
       ..strokeWidth = 5
       ..strokeCap = StrokeCap.round;
     
     // Goal posts + crossbar
     final goalLeft = (w - w * 0.85) / 2;
     final goalRight = w - goalLeft;
     final goalBottom = zoneHeight * 0.9;
     
     // Left post
     canvas.drawLine(Offset(goalLeft, 0), Offset(goalLeft, goalBottom), framePaint);
     // Right post
     canvas.drawLine(Offset(goalRight, 0), Offset(goalRight, goalBottom), framePaint);
     // Crossbar (bottom of goal zone)
     canvas.drawLine(Offset(goalLeft, goalBottom), Offset(goalRight, goalBottom), framePaint);
     
     // Post shadows (3D depth)
     final shadowPaint = Paint()
       ..color = Colors.black.withValues(alpha: 0.2)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 3;
     canvas.drawLine(Offset(goalLeft + 3, 0), Offset(goalLeft + 3, goalBottom), shadowPaint);
     canvas.drawLine(Offset(goalRight + 3, 0), Offset(goalRight + 3, goalBottom), shadowPaint);

     // 4. GOAL FLASH (on score)
     if (goalFlash > 0) {
        final flashPaint = Paint()
          ..color = Colors.greenAccent.withValues(alpha: goalFlash * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(goalLeft, 0, goalRight - goalLeft, goalBottom), flashPaint);
     }

     // 5. DRAG ARROW (Shot direction indicator)
     if (dragStart != null && dragCurrent != null) {
        final Offset start = ballCenter; 
        final dx = dragCurrent!.dx - dragStart!.dx;
        final dy = dragCurrent!.dy - dragStart!.dy;
        double len = sqrt(dx*dx + dy*dy);
        double maxLen = 100.0;
        double scale = 1.0;
        if (len > maxLen) scale = maxLen / len;
        
        final end = start + Offset(dx*scale, dy*scale);
        final paintArrow = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(start, end, paintArrow);
        
        double angle = atan2(dy, dx);
        double arrowHeadLen = 12.0;
        final p1 = end - Offset(cos(angle - pi/6)*arrowHeadLen, sin(angle - pi/6)*arrowHeadLen);
        final p2 = end - Offset(cos(angle + pi/6)*arrowHeadLen, sin(angle + pi/6)*arrowHeadLen);
        canvas.drawLine(end, p1, paintArrow);
        canvas.drawLine(end, p2, paintArrow);
     }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
