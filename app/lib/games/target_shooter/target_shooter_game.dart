import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/games/physics/game_engine.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform
import 'dart:async'; // For StreamSubscription

// New Imports
import 'package:talkbingo_app/games/config/target_shooter_config.dart';
import 'package:talkbingo_app/games/config/responsive_config.dart';
import 'package:talkbingo_app/widgets/game_header.dart';
import 'package:talkbingo_app/widgets/power_gauge.dart';
import 'package:talkbingo_app/widgets/mini_game_coach_overlay.dart';
import 'package:talkbingo_app/services/onboarding_service.dart';

class TargetShooterGame extends StatefulWidget {
  final VoidCallback onWin; 
  final VoidCallback onClose;

  const TargetShooterGame({
    super.key,
    required this.onWin,
    required this.onClose,
  });

  @override
  State<TargetShooterGame> createState() => _TargetShooterGameState();
}

class _TargetShooterGameState extends State<TargetShooterGame> with TickerProviderStateMixin {
  final GameSession _session = GameSession();
  late Ticker _ticker;
  double _lastTime = 0;
  
  // Animation for Bow String Vibration
  late AnimationController _vibController;
  late Animation<double> _vibAnimation;
  
  // Game Entities
  late GameEntity _target;
  late GameEntity _player;
  final List<GameEntity> _bullets = [];
  final List<Map<String, dynamic>> _stuckArrows = []; // {x, y, angle} relative to Target
  
  // Platform & Responsive Config
  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  // Config (Initialized in build/LayoutBuilder)
  TargetShooterConfig? _config;
  
  // Game State
  int _score = 0;
  bool _isRoundActive = false;
  bool _isRoundOver = false;
  double _timeLeft = 15.0;
  bool _showRoundOverlay = false;

  // Sync
  DateTime _lastSync = DateTime.now();
  DateTime _lastAimSync = DateTime.now();
  DateTime _lastTimeSync = DateTime.now(); // For timer sync
  StreamSubscription? _eventSub;
  int _lastKnownRound = 0;
  bool _isWaitingForStart = true;
  bool _isPaused = false; // Mini-game pause (stops broadcast + timer)
  
  // Spectator State
  double _remoteAimAngle = 0;
  double _remoteDrawAmt = 0;
  int _remoteScore = 0; // Track opponent score locally
  
  // Current Draw Power (0.0 - 1.0) for Gauge
  double _currentPower = 0.0;
  
  // Hit Effects
  final List<Map<String, dynamic>> _hitParticles = []; // {x, y, opacity, vx, vy}
  final List<Map<String, dynamic>> _scorePopups = []; // {x, y, text, opacity, vy}
  
  // Size
  Size _gameSize = Size.zero;
  bool _showCoachOverlay = false;

  @override
  void initState() {
    super.initState();
    // Initialize Defaults (Sizes will be updated in LayoutBuilder)
    _target = GameEntity(x: 0, y: 0, width: 100, height: 30, color: Colors.orange);
    _player = GameEntity(x: 0, y: 0, width: 100, height: 100, color: AppColors.hostPrimary);
    
    // Setup Vibration Animation
    _vibController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _vibAnimation = Tween<double>(begin: 0, end: 10).animate(
       CurvedAnimation(parent: _vibController, curve: Curves.elasticOut)
    );
    
    _ticker = createTicker(_onTick)..start();
    _session.addListener(_onSessionUpdate);
    _eventSub = _session.gameEvents.listen(_onGameEvent);
    
    // Check coach mark
    OnboardingService.shouldShowCoachMark('mini_target').then((show) {
      if (show && mounted) setState(() => _showCoachOverlay = true);
    });
    
    // Check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkRoundState(); 
      if (_gameSize != Size.zero) _repositionEntities();
    });
  }
  
  void _updateConfig(Size size) {
     if (_config?.screenSize != size) {
        // We assume 'size' comes from LayoutBuilder, so it IS the Game Area.
        _config = TargetShooterConfig(size, isGameArea: true);
        // Don't call _repositionEntities() here as it's called by the caller
     }
  }
  
  void _onSessionUpdate() {
      if (mounted) setState(() { _checkRoundState(); });
  }

  void _onGameEvent(Map<String, dynamic> payload) {
     if (_gameSize == Size.zero) return;
     
     final activePlayer = _session.interactionState?['activePlayer'];
     final isShooter = activePlayer == _session.myRole;

     if (payload['eventType'] == 'round_start') {
       if (!isShooter) {
          _isWaitingForStart = false;
          _isRoundActive = true;
          _timeLeft = 15.0; // Full time when spectator joins
          setState(() {});
       }
     } else if (payload['eventType'] == 'score_update') {
         // Real-time Score Sync
         if (payload.containsKey('score')) {
            setState(() {
               // Update the score of the player who sent this
               // If I am shooter, opponent sent it? No, Shooter sends their score.
               // If I am spectator, Shooter sent it.
               if (!isShooter) {
                  // I am Spectator, update Shooter's score (which is 'activePlayer')
                  _remoteScore = (payload['score'] as num).toInt();
                  // Also update local score tracker for UI if needed
               }
            });
         }
     } else if (payload['eventType'] == 'time_sync') {
         if (!isShooter && payload.containsKey('time')) {
             double serverTime = (payload['time'] as num).toDouble();
             // Soft sync: if difference is large, snap. Else lerp?
             // For simplicity, just snap for now, or use as authoritative
             if ((_timeLeft - serverTime).abs() > 2.0) {
                 _timeLeft = serverTime;
             }
         }
     } else if (payload['eventType'] == 'target_move') {
        if (!isShooter) {
           final double normX = (payload['x'] as num).toDouble();
           final double normVX = (payload.containsKey('vx')) ? (payload['vx'] as num).toDouble() : 0.0;
           double newX = normX * (_gameSize.width - _target.width);
           if ((_target.x - newX).abs() > 20) {
              _target.x = newX;
           } else {
              _target.x = _target.x * 0.8 + newX * 0.2;
           }
           _target.vx = normVX * _gameSize.width;
        }
     } else if (payload['eventType'] == 'aim') {
        if (!isShooter) {
           setState(() {
              _remoteAimAngle = (payload['angle'] as num).toDouble();
              _remoteDrawAmt = (payload['draw'] as num).toDouble();
           });
           // If released (draw goes to 0 from high), trigger vibe?
           // Simplification: Just sync state. If draw resets to 0, visually it snaps back.
        }
     } else if (payload['eventType'] == 'shot') {
        if (!isShooter) {
           final double normX = (payload['x'] as num).toDouble();
           final double normY = (payload['y'] as num).toDouble();
           final double normVX = (payload['vx'] as num).toDouble();
           final double normVY = (payload['vy'] as num).toDouble();
           final b = GameEntity(
             x: normX * _gameSize.width,
             y: normY * _gameSize.height,

             width: _config!.arrowWidth,
             height: _config!.arrowHeight,
             color: Colors.redAccent,
             vx: normVX * _gameSize.width,
             vy: normVY * _gameSize.height,
           );
           _bullets.add(b);
           // Trigger vibration on remote shot to feel alive
           _vibController.forward(from: 0);
           _remoteDrawAmt = 0; // Reset remote draw
           if (mounted) setState(() {});
        }
     } else if (payload['eventType'] == 'stuck_arrow') {
         // Opponent hit the target — show stuck arrow on my screen too
         if (!isShooter) {
            final double rx = (payload['rx'] as num).toDouble();
            final double ry = (payload['ry'] as num).toDouble();
            final double angle = (payload['angle'] as num).toDouble();
            setState(() {
               _stuckArrows.add({
                  'x': rx * _target.width,
                  'y': ry * _target.height,
                  'angle': angle,
               });
            });
         }
      } else if (payload['eventType'] == 'game_pause') {
         setState(() => _isPaused = true);
      } else if (payload['eventType'] == 'game_resume') {
         setState(() => _isPaused = false);
      }
  }
  
  void _repositionEntities() {
      if (_config == null) return;
      
      // Update Sizes from Config
      _target.width = _config!.targetWidth;
      _target.height = _config!.targetHeight;
      _player.width = _config!.playerSize;
      _player.height = _config!.playerSize;

      // Position Player (활) - Center horizontally, positioned for easy touch
      _player.x = _config!.safeGameArea.width / 2 - _player.width / 2;
      // Use config value - positioned at 70% from top for comfortable reach
      _player.y = _config!.playerY;
      
      // Position Target (과녘) - Top
      _target.y = _config!.targetY;
      
      final activePlayer = _session.interactionState?['activePlayer'];
      final isShooter = activePlayer == _session.myRole;

      // Initialize target position only if not already set or if velocity is 0
      if (isShooter && (_target.vx == 0 || _target.x == 0)) {
         _target.x = _config!.safeGameArea.width / 2 - _target.width/2;
         _target.vx = _config!.targetSpeed; 
      } else if (!isShooter) {
         // Spectator: don't reset position/velocity
         if (_target.x == 0) {
            _target.x = _config!.safeGameArea.width / 2 - _target.width/2;
         }
      }
   }



  void _checkRoundState() {
    final state = _session.interactionState;
    if (state == null) return;
    
    final round = state['round'] ?? 1;

    // Detect Round Change
    if (round != _lastKnownRound) {
       _lastKnownRound = round;
       
       // Force Reset Logic for new Round
       _resetGame(); 
       
       // Set Waiting State
       _isWaitingForStart = true;
       _isRoundActive = false;
       _showRoundOverlay = true;

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

  void _resetGame() {
    _score = 0;
    _isRoundOver = false;
    _timeLeft = 15.0;
    _bullets.clear();
    _stuckArrows.clear();
    _hitParticles.clear();
    _scorePopups.clear();
    _isPaused = false;
    _remoteAimAngle = 0;
    _remoteDrawAmt = 0;
    _remoteScore = 0;
    _currentPower = 0.0;
    
    // Initialize with placeholders, repositionEntities will set correct sizes
    _target = GameEntity(x: 0, y: 0, width: 100, height: 30, color: Colors.orange);
    _player = GameEntity(x: 0, y: 0, width: 100, height: 100, color: AppColors.hostPrimary);
    
    if (_gameSize != Size.zero) {
       _repositionEntities();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionUpdate);
    _eventSub?.cancel();
    _ticker.dispose();
    _vibController.dispose();
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
    
    // Timer (Authoritative for Shooter)
    final activePlayer = _session.interactionState?['activePlayer'];
    if (activePlayer == _session.myRole) {
       _timeLeft -= dt;
       
       // Sync Time occasionally
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
       // Spectator just visual decrease, loosely sync via 'time_sync'
       // Don't finish locally, wait for Shooter to finish (via session update or event)
       _timeLeft -= dt;
       if (_timeLeft < 0) _timeLeft = 0;
    }

    _updateGame(dt);
    if (mounted) setState(() {}); 
  }
  
  Future<void> _finishRound() async {
    _isRoundActive = false;
    _isRoundOver = true;
    setState(() {}); 
    await _session.submitMiniGameScore(_score);
  }



  void _updateGame(double dt) {
      final activePlayer = _session.interactionState?['activePlayer'];
      final isShooter = activePlayer == _session.myRole;

      // 1. Update Target
      if (isShooter) {
         // I am Shooter (Active Player) -> Control Target AI
         // AI Logic: Move Target Left/Right with sine wave or constant speed bounce
         _target.x += _target.vx * dt;
         if (_target.x <= 0) {
            _target.x = 0;
            _target.vx = _target.vx.abs();
         } else if (_target.x + _target.width >= _gameSize.width) {
            _target.x = _gameSize.width - _target.width;
            _target.vx = -_target.vx.abs();
         }
         
         // Sync Target Pos to Spectator
         if (DateTime.now().difference(_lastSync).inMilliseconds > 50) {
            double normX = (_target.x) / (_gameSize.width - _target.width);
            double normVX = _target.vx / _gameSize.width; // Normalize Velocity
            _session.sendGameEvent({'eventType': 'target_move', 'x': normX, 'vx': normVX});
            _lastSync = DateTime.now();
         }
      } else {
         // I am Spectator -> Predict Target Movement
         _target.x += _target.vx * dt;
         
         // Simple Bounce Prediction
         if (_target.x <= 0) {
             _target.x = 0;
             _target.vx = _target.vx.abs();
         } else if (_target.x + _target.width >= _gameSize.width) {
             _target.x = _gameSize.width - _target.width;
             _target.vx = -_target.vx.abs();
         }
      }

      
      // 2. Update Bullets
      // Bullets are local to Shooter? 
      // If we want Spectator to see shots, we need to sync shots or bullets.
      // Currently `shoot` event is missing? 
      // Let's add Sync for Shot in _onPanEnd.
      
      // Update Bullets (Both sides need to run physics for bullets they know about)
      for (var b in _bullets) {
        if (b.isDead) continue;
        b.update(dt);
        // Collision: Only Authoritative on Shooter side?
        // Or both simulate?
        // Let's make Shooter Authoritative.
        
        if (isShooter) {
           // 1. Raycast Hit Detection (Tip-Based with Rotation)
           
           // Target Hitbox (Visual Area Only)
           // Shrink by 10% on each side to match SVG "meat"
           Rect targetRect = Rect.fromLTWH(
               _target.x + _target.width * 0.1, 
               _target.y + _target.height * 0.2, 
               _target.width * 0.8, 
               _target.height * 0.6
           );
           
           // Calculate Rotated Tip Position
           double theta = (b.vx != 0 || b.vy != 0) ? atan2(b.vy, b.vx) + pi/2 : 0;
           
           // Arrow center
           final cx = b.x + b.width / 2;
           final cy = b.y + b.height / 2;

           double tipX, tipY;
           if (b.vx == 0 && b.vy == 0) {
              tipX = cx; tipY = cy - b.height/2;
           } else {
              double velMag = sqrt(b.vx*b.vx + b.vy*b.vy);
              tipX = cx + (b.vx / velMag) * (b.height / 2);
              tipY = cy + (b.vy / velMag) * (b.height / 2);
           }
           
           // Previous Tip (Approximate for tunneling check)
           double prevX = b.x - b.vx * dt;
           double prevY = b.y - b.vy * dt;
           double prevCx = prevX + b.width/2;
           double prevCy = prevY + b.height/2;
           double prevTipX, prevTipY;
           if (b.vx == 0 && b.vy == 0) {
              prevTipX = prevCx; prevTipY = prevCy - b.height/2;
           } else {
              double velMag = sqrt(b.vx*b.vx + b.vy*b.vy);
              prevTipX = prevCx + (b.vx / velMag) * (b.height / 2);
              prevTipY = prevCy + (b.vy / velMag) * (b.height / 2);
           }
           
           // 1. Point Check (Current Tip)
           if (targetRect.contains(Offset(tipX, tipY))) {
                b.isDead = true;
                _stickArrow(b, tipX, tipY);
           }
           // 2. Raycast Check (Tunneling - Line Segment vs Rect)
           // If we crossed the bottom edge of the target
           else if (!b.isDead && prevTipY > targetRect.bottom && tipY < targetRect.bottom) {
                // Find X intersection at bottom
                // t = (Y_target - Y_prev) / (Y_curr - Y_prev)
                double t = (targetRect.bottom - prevTipY) / (tipY - prevTipY);
                double intersectX = prevTipX + t * (tipX - prevTipX);
                
                if (intersectX >= targetRect.left && intersectX <= targetRect.right) {
                    b.isDead = true;
                    // Stick at intersection
                    _stickArrow(b, intersectX, targetRect.bottom - 2);
                    continue;
                }
           }
           
           if (!b.isDead && b.y < -50) b.isDead = true;
        } else {
           // Spectator: Just Visuals
           if (b.y < -50) b.isDead = true;
        }
      }
      _bullets.removeWhere((b) => b.isDead);
      
      // Update Hit Particles
      for (var p in _hitParticles) {
        p['x'] = (p['x'] as double) + (p['vx'] as double) * dt;
        p['y'] = (p['y'] as double) + (p['vy'] as double) * dt;
        p['opacity'] = ((p['opacity'] as double) - dt * 2.0).clamp(0.0, 1.0);
      }
      _hitParticles.removeWhere((p) => (p['opacity'] as double) <= 0);
      
      // Update Score Popups
      for (var s in _scorePopups) {
        s['y'] = (s['y'] as double) + (s['vy'] as double) * dt;
        s['opacity'] = ((s['opacity'] as double) - dt * 1.5).clamp(0.0, 1.0);
      }
      _scorePopups.removeWhere((s) => (s['opacity'] as double) <= 0);
  }

  void _stickArrow(GameEntity b, double hitX, double hitY) {
       double relX = hitX - _target.x - (_config!.arrowWidth/2);
       double relY = hitY - _target.y;
       double angle = (b.vx != 0 || b.vy != 0) ? atan2(b.vy, b.vx) + pi/2 : 0;
       
       _stuckArrows.add({
          'x': relX,
          'y': relY,
          'angle': angle,
       });
       
       // Broadcast stuck arrow to opponent (normalized)
       _session.sendGameEvent({
          'eventType': 'stuck_arrow',
          'rx': relX / _target.width,  // normalized relative X
          'ry': relY / _target.height, // normalized relative Y
          'angle': angle,
       });
       
       _handleHit(); // Trigger Score update
  }
  
  void _handleHit() {
    _score++;
    
    // Real-time Score Sync
    _session.sendGameEvent({'eventType': 'score_update', 'score': _score});
    
    // Hit Particles (Sparkle Burst)
    final hitX = _target.x + _target.width / 2;
    final hitY = _target.y + _target.height / 2;
    final rng = Random();
    for (int i = 0; i < 8; i++) {
      double angle = (i / 8) * 2 * pi + rng.nextDouble() * 0.5;
      double speed = 80.0 + rng.nextDouble() * 120.0;
      _hitParticles.add({
        'x': hitX, 'y': hitY,
        'vx': cos(angle) * speed,
        'vy': sin(angle) * speed,
        'opacity': 1.0,
        'color': [Colors.amber, Colors.orangeAccent, Colors.white, Colors.redAccent][i % 4],
      });
    }
    
    // Score Popup
    _scorePopups.add({
      'x': hitX, 'y': hitY - 20,
      'text': '+1', 'opacity': 1.0, 'vy': -60.0,
    });
    
    if (mounted) setState(() {});
  }
  
  // Aiming State
  Offset? _aimStart;
  Offset? _aimCurrent;
  
  void _onPanStart(DragStartDetails details) {
    final activePlayer = _session.interactionState?['activePlayer'];
    final isShooter = activePlayer == _session.myRole;
    
    // SPECTATOR IGNORED
    if (isShooter) {
        setState(() {
          _aimStart = details.localPosition;
          _aimCurrent = details.localPosition;
          _currentPower = 0.0;
        });
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (_config == null) return;
    final activePlayer = _session.interactionState?['activePlayer'];
    final isShooter = activePlayer == _session.myRole;
    
    // SPECTATOR IGNORED
    if (isShooter) {
        setState(() {
          _aimCurrent = details.localPosition;
          
          // Calculate Power for Gauge
          double dx = _aimStart!.dx - _aimCurrent!.dx; 
          double dy = _aimStart!.dy - _aimCurrent!.dy; 
          double pullDist = sqrt(dx*dx + dy*dy);
          double maxPull = 300.0; 
          _currentPower = (pullDist / maxPull).clamp(0.0, 1.0);
          
          // SYNC AIMING
          if (DateTime.now().difference(_lastAimSync).inMilliseconds > 50) {
              double dx = _aimStart!.dx - _aimCurrent!.dx;
              double dy = _aimStart!.dy - _aimCurrent!.dy;
              double angle = atan2(dy, dx) + pi/2;
              double drawAmt = sqrt(dx*dx + dy*dy).clamp(0, 100);
              
              _session.sendGameEvent({
                 'eventType': 'aim',
                 'angle': angle,
                 'draw': drawAmt
              });
              _lastAimSync = DateTime.now();
          }
        });
    }
  }
  
  void _onPanEnd(DragEndDetails details) {
    final activePlayer = _session.interactionState?['activePlayer'];
    final isShooter = activePlayer == _session.myRole;
    
    if (isShooter && _aimStart != null && _aimCurrent != null) {
       // Vector from Current (Finger) to Start (Anchor)
       double dx = _aimStart!.dx - _aimCurrent!.dx; 
       double dy = _aimStart!.dy - _aimCurrent!.dy; 
       
       double pullDist = sqrt(dx*dx + dy*dy);
       if (pullDist > _config!.touchThreshold) { 
          // Fire!
          double maxPull = _config?.aimLineLength ?? 300.0;
          double power = (pullDist / maxPull).clamp(0.2, 1.2); 
          
          final b = GameEntity(
            x: _player.x + _player.width/2 - _config!.arrowWidth/2,
            y: _player.y, 
            width: _config!.arrowWidth,
            height: _config!.arrowHeight, 
            color: Colors.redAccent,
            vx: (dx / pullDist) * 800 * power,
            vy: (dy / pullDist) * 800 * power,
          );
          _bullets.add(b);
          
          // Vibrate Bow
          _vibController.forward(from: 0);

          // SYNC SHOT TO SPECTATOR (Normalized)
          if (_gameSize.width > 0 && _gameSize.height > 0) {
             _session.sendGameEvent({
                'eventType': 'shot', 
                'x': b.x / _gameSize.width, 
                'y': b.y / _gameSize.height, 
                'vx': b.vx / _gameSize.width, 
                'vy': b.vy / _gameSize.height
             });
          }
       }
       setState(() {
          _aimStart = null;
          _aimCurrent = null;
          _currentPower = 0.0;
          
          // Reset Aim Sync
          _session.sendGameEvent({'eventType': 'aim', 'angle': 0, 'draw': 0});
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Config Update removed from here, moved to LayoutBuilder
    // final size = MediaQuery.of(context).size;
    // if (_config == null || _config!.screenSize != size) {
    //    _updateConfig(size);
    // }

    final state = _session.interactionState;
    if (state == null) return const SizedBox(); 

    final activePlayer = state['activePlayer'];
    final isShooter = activePlayer == _session.myRole;
    final round = state['round'] ?? 1;
    final scores = state['scores'] ?? {}; 
    
    // Aiming Logic (Local or Remote)
    double bowAngle = 0; 
    double drawAmt = 0;
    
    if (isShooter) {
        if (_aimStart != null && _aimCurrent != null) {
           double dx = _aimStart!.dx - _aimCurrent!.dx;
           double dy = _aimStart!.dy - _aimCurrent!.dy;
           bowAngle = atan2(dy, dx) + pi/2;
           drawAmt = sqrt(dx*dx + dy*dy).clamp(0, _config?.aimLineLength ?? 100);
        }
    } else {
        // Use Remote State
        bowAngle = _remoteAimAngle;
        drawAmt = _remoteDrawAmt;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0118),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // 1. GAME HEADER
             GameHeader(
               gameTitle: "ARROW SHOT",
               score: isShooter ? _score : _remoteScore,
               opponentScore: isShooter ? _remoteScore : (scores[_session.myRole] ?? 0),
               timeLeft: _timeLeft,
               isMyTurn: isShooter,
               onMenuTap: widget.onClose,
             ),

            // 2. GAME AREA (Draggable)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Init Game Size and Config
                  final needsUpdate = _gameSize != constraints.biggest;
                  if (needsUpdate) {
                     _gameSize = constraints.biggest;
                     // Update Config with ACTUAL Game Area Size
                     _updateConfig(_gameSize);
                     // Only reposition when config changes, not every frame
                     _repositionEntities();
                  }

                  // Ensure config is ready before rendering content dependent on it
                  if (_config == null) {
                    return const SizedBox();
                  }

                  return GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        // Background Gradient (Space Theme)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF0A0118),   
                                  const Color(0xFF150830),   
                                  const Color(0xFF1A0A3E),  
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // TARGET (Top) - 3-Tier Bar
                        if (_gameSize.width > 0)
                        Positioned(
                          left: _target.x,
                          top: _target.y,
                          width: _target.width,
                          height: _target.height,
                          child: SvgPicture.asset(
                             'assets/images/Targetboard.svg',
                             fit: BoxFit.contain,
),
                        ),

                        // STUCK ARROWS (Attached to Target with Glow)
                        ..._stuckArrows.map((a) => Positioned(
                            left: _target.x + (a['x'] as num).toDouble(), 
                            top: _target.y + (a['y'] as num).toDouble(),
                            width: _config!.stuckArrowWidth,
                            height: _config!.stuckArrowHeight,
                            child: Transform.rotate(
                                angle: (a['angle'] as num).toDouble(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset('assets/images/arrow.svg', fit: BoxFit.contain),
                                )
                            )
                        )),

                        // ARROWS (Projectiles)
                        ..._bullets.map((b) {
                           // Calculate Angle from velocity
                           double angle = atan2(b.vy, b.vx) + pi/2; 
                           return Positioned(
                              left: b.x,
                              top: b.y,
                              width: b.width,
                              height: b.height,
                              child: Transform.rotate(
                                angle: angle,
                                child: SvgPicture.asset(
                                   'assets/images/arrow.svg',
                                   fit: BoxFit.contain,
),
                              )
                           );
                        }),
                        
                        // PLAYER (Bow) - Bottom
                        if (_gameSize.width > 0)
                        Positioned(
                           left: _player.x,
                           top: _player.y,
                           width: _player.width,
                           height: _player.height,
                           child: Transform.rotate(
                             angle: bowAngle, 
                             child: Stack(
                               alignment: Alignment.center,
                               children: [
                                  // Bow
                                  Transform.rotate(
                                    angle: -pi / 2, // Fix: Align Bow (Native Right) to Up
                                    child: SvgPicture.asset(
                                      drawAmt > 10 ? 'assets/images/Bow_2.svg' : 'assets/images/Bow.svg',
                                      fit: BoxFit.contain,
),
                                  ),
                                  // Arrow on Bow (if aiming)
                                  if (drawAmt > 5)
                                    Positioned( 
                                      top: 20 + drawAmt/2, 
                                      child: SvgPicture.asset(
                                        'assets/images/arrow.svg', 
                                        height: _config!.arrowHeight, 
                                        fit: BoxFit.fitHeight,
)
                                    )
                               ]
                             )
                           ),
                        ),
                        
                        // HIT PARTICLES (Sparkle Burst)
                        ..._hitParticles.map((p) => Positioned(
                            left: (p['x'] as double) - 4,
                            top: (p['y'] as double) - 4,
                            child: Opacity(
                              opacity: (p['opacity'] as double),
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p['color'] as Color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (p['color'] as Color).withOpacity(0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                ),
                              ),
                            )
                        )),

                        // SCORE POPUPS (+1)
                        ..._scorePopups.map((s) => Positioned(
                            left: (s['x'] as double) - 20,
                            top: (s['y'] as double),
                            child: Opacity(
                              opacity: (s['opacity'] as double),
                              child: Text(
                                s['text'] as String,
                                style: GoogleFonts.alexandria(
                                  color: Colors.amber,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.orange, blurRadius: 8),
                                  ],
                                ),
                              ),
                            )
                        )),

                        // POWER GAUGE
                        if (isShooter && _aimStart != null)
                           Positioned(
                              bottom: _player.height + 20,
                              left: 0, right: 0,
                              child: Center(
                                 child: PowerGauge(power: _currentPower, label: "POWER", showLevels: true)
                              )
                           ),

                        // MANUAL START OVERLAY (pre-game)
                        if (_isWaitingForStart && !_showRoundOverlay && state['step'] != 'finished')
                           Container(
                              color: Colors.black.withOpacity(0.8),
                              alignment: Alignment.center,
                              child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                    Text(
                                       isShooter ? "YOU ARE SHOOTER" : "SPECTATOR MODE",
                                       style: GoogleFonts.alexandria(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 20),
                                    if (isShooter) ...[
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
                                           Text("Waiting for Shooter...", style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 14)),
                                        ],
                                      ),
                                 ],
                              ),
                           ),

                        // ROUND CHANGE OVERLAY
                        if (_showRoundOverlay)
                           Container(
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
                                       isShooter ? "SHOOT!" : "DODGE!", 
                                       style: GoogleFonts.alexandria(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                    ),
                                 ],
                              ),
                           ),



                      ],  // Stack children
                    ),   // Stack
                  );     // GestureDetector
                }
              ),  // LayoutBuilder
            ),    // Expanded
          ],      // Column children
        ),        // Column
      ),          // SafeArea

          // ── Coach Mark Overlay ──
          if (_showCoachOverlay)
            Positioned.fill(
              child: MiniGameCoachOverlay(
                gameType: 'target',
                onClose: () {
                  setState(() => _showCoachOverlay = false);
                  if (_isWaitingForStart) _startRoundManually();
                },
              ),
            ),
        ],
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
                      _buildBigScore("YOU", isShooter ? _score : (scores[_session.myRole] ?? 0), isShooter),
                      const SizedBox(width: 40),
                      Text("VS", style: GoogleFonts.alexandria(color: Colors.white24, fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 40),
                      _buildBigScore("OPPONENT", scores[isShooter ? (_session.myRole == 'A' ? 'B' : 'A') : activePlayer] ?? 0, !isShooter),
                   ],
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.hostPrimary, 
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
           color: isActive ? AppColors.hostPrimary.withOpacity(0.8) : Colors.grey.withOpacity(0.2),
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



class _BowStringPainter extends CustomPainter {
  final double drawAmt;
  final double vibration;
  
  _BowStringPainter({required this.drawAmt, this.vibration = 0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paintString = Paint()
      ..color = Colors.white
      ..strokeWidth = 3 // Thicker string to match visual
      ..style = PaintingStyle.stroke;
      
    // Bow_2.svg Native Size: 176x58
    // Tips are at X=0, Y=53 and X=176, Y=53 relative to 176x58 viewBox.
    // The rendered widget (SizedBox) fits 'contain' within size using aspect ratio.
    // We assume the widget Size passed here matches the aspect ratio or fills it.
    
    // Calculate scale factor if size differs from native, or just map relative %
    // Tips are at ~91% of height (53/58).
    
    // Let's assume the SVG is rendered to FILL width (176 units -> size.width)
    // Then height corresponds to size.width * (58/176)? 
    // Actually the parent is sized to _player.width/height (160x160).
    // fit: BoxFit.contain means it will be limited by width (160) likely, creating empty vertical space if height is big?
    // Wait, 176x58 is wide. 160x160 is square.
    // So the bow will fit WIDTH (160 px).
    // The rendered height will be 160 * (58/176) = 52.7 px.
    // The SvgPicture is centered in the 160x160 box or top aligned? 
    // It is in a Stack, size is _player.width x height. Default alignment is top-left usually for Positioned or Center for Stack?
    // The Stack in 'build' is: Stack(children: [CustomPaint, SvgPicture, ...])
    // SvgPicture default alignment in SizedBox is Center.
    
    // To align perfectly, we need to know WHERE the SvgPicture draws itself.
    // Since aspect ratio is ~3:1 and container is 1:1, it will be centered vertically.
    // Rendered Height = size.width * (58/176).
    // Top Offset = (size.height - RenderedHeight) / 2.
    // Tips Y in Rendered Image = RenderedHeight * (53/58) = size.width * (53/176).
    // Actual TipY = Top Offset + Tips Y.
    
    final double renderedHeight = size.width * (58.0 / 176.0);
    final double topOffset = (size.height - renderedHeight) / 2;
    final double relTipY = renderedHeight * (53.0 / 58.0);
    
    final double finalTipY = topOffset + relTipY;
    
    final tipL = Offset(0, finalTipY);
    final tipR = Offset(size.width, finalTipY);
    
    final centerX = size.width / 2;
    // Nock point (Center)
    // When idle, it should be at finalTipY.
    
    if (drawAmt > 0) {
       // Pulled Back: Triangle
       final nock = Offset(centerX, finalTipY + drawAmt);
       canvas.drawLine(tipL, nock, paintString);
       canvas.drawLine(tipR, nock, paintString);
    } else {
       // Straight Line (Idle) + Vibration
       final midX = centerX;
       final midY = finalTipY + vibration; 

       if (vibration.abs() > 0.1) {
          // Vibrating curve
          final path = Path();
          path.moveTo(tipL.dx, tipL.dy);
          path.quadraticBezierTo(midX, midY, tipR.dx, tipR.dy);
          canvas.drawPath(path, paintString);
       } else {
          // Dead straight - Coincides with SVG's static string if visible
          canvas.drawLine(tipL, tipR, paintString);
       }
    }
  }

  @override
  bool shouldRepaint(covariant _BowStringPainter oldDelegate) => oldDelegate.drawAmt != drawAmt || oldDelegate.vibration != vibration;
}
