import 'package:flutter/material.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/games/target_shooter/target_shooter_game.dart';
import 'package:talkbingo_app/games/penalty_kick/penalty_kick_game.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

class MiniGameTestScreen extends StatefulWidget {
  const MiniGameTestScreen({super.key});

  @override
  State<MiniGameTestScreen> createState() => _MiniGameTestScreenState();
}

class _MiniGameTestScreenState extends State<MiniGameTestScreen> {
  final GameSession _session = GameSession();
  
  // Test State
  String _selectedGame = 'target_shooter'; // or 'penalty_kick'
  String _myRole = 'A'; // A = Host, B = Guest
  int _round = 1;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupSession();
  }

  void _setupSession() {
    _session.myRole = _myRole;
    // Dummy Interaction State
    _session.interactionState = {
      'gameType': _selectedGame,
      'activePlayer': 'A', // Default Attacker
      'round': _round,
      'step': 'playing',
      'scores': {'A': 0, 'B': 0},
      'winner': null
    };
    setState(() {});
  }

  void _toggleRole() {
    setState(() {
      _myRole = (_myRole == 'A') ? 'B' : 'A';
      _setupSession();
    });
  }

  void _toggleGame() {
    setState(() {
      _selectedGame = (_selectedGame == 'target_shooter') ? 'penalty_kick' : 'target_shooter';
      _setupSession();
    });
  }
  
  void _startGame() {
      setState(() => _isPlaying = true);
  }
  
  void _stopGame() {
      setState(() => _isPlaying = false);
  }

  // --- SIMULATION ---
  void _simRoundStart() {
     _session.injectTestEvent({'eventType': 'round_start'});
  }

  void _simOpponentScore() {
    // If I am A, Opponent is B.
    String opp = _myRole == 'A' ? 'B' : 'A';
    int currentScore = (_session.interactionState!['scores'][opp] ?? 0) + 1;
    _session.interactionState!['scores'][opp] = currentScore;
    
    // Send event as if it came from Opponent
    _session.injectTestEvent({'eventType': 'score_update', 'score': currentScore});
  }

  void _simOpponentMove() {
     // Sim random movement for sync test
     if (_selectedGame == 'target_shooter') {
        _session.injectTestEvent({
           'eventType': 'target_move', 
           'x': 0.5, 
           'vx': 100.0
        });
     } else {
        _session.injectTestEvent({
           'eventType': 'goalie_move', 
           'x': 0.5, 
           'vx': 0.5
        });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Row(
        children: [
          // 1. Control Panel (Left)
          Container(
            width: 300,
            color: Colors.grey[850],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("TEST HARNESS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white54),
                
                // Game Selection
                ListTile(
                  title: const Text("Target Shooter", style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    value: 'target_shooter', 
                    groupValue: _selectedGame, 
                    onChanged: (v) => _toggleGame(),
                    activeColor: AppColors.hostPrimary,
                  ),
                ),
                ListTile(
                  title: const Text("Penalty Kick", style: TextStyle(color: Colors.white)),
                  leading: Radio(
                    value: 'penalty_kick', 
                    groupValue: _selectedGame, 
                    onChanged: (v) => _toggleGame(),
                    activeColor: AppColors.hostPrimary,
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text("MY ROLE", style: TextStyle(color: Colors.grey)),
                Row(
                   children: [
                      Expanded(
                        child: ElevatedButton(
                           style: ElevatedButton.styleFrom(backgroundColor: _myRole == 'A' ? Colors.blue : Colors.grey),
                           onPressed: () { setState(() { _myRole = 'A'; _setupSession(); }); },
                           child: const Text("HOST (A)"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                           style: ElevatedButton.styleFrom(backgroundColor: _myRole == 'B' ? Colors.red : Colors.grey),
                           onPressed: () { setState(() { _myRole = 'B'; _setupSession(); }); },
                           child: const Text("GUEST (B)"),
                        ),
                      ),
                   ],
                ),
                const SizedBox(height: 10),
                Text(
                   _myRole == 'A' ? "You are ATTACKER/SHOOTER" : "You are DEFENDER/SPECTATOR",
                   style: const TextStyle(color: Colors.greenAccent),
                ),

                const SizedBox(height: 30),
                const Text("SIMULATION", style: TextStyle(color: Colors.grey)),
                ElevatedButton(
                   onPressed: _simRoundStart,
                   child: const Text("Simulate 'Round Start'"),
                ),
                ElevatedButton(
                   onPressed: _simOpponentScore,
                   child: const Text("Simulate Opponent Score (+1)"),
                ),
                ElevatedButton(
                   onPressed: _simOpponentMove,
                   child: const Text("Simulate Opponent Move"),
                ),
                
                const Spacer(),
                if (!_isPlaying)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
                    onPressed: _startGame,
                    child: const Text("LAUNCH GAME", style: TextStyle(fontSize: 18)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(20)),
                    onPressed: _stopGame,
                    child: const Text("STOP GAME", style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
          
          // 2. Game Preview (Right)
          Expanded(
            child: Container(
               color: Colors.black,
               child: Center(
                 child: _isPlaying 
                   ? Container(
                       // Constrain to emulate mobile if needed, or full
                       constraints: const BoxConstraints(maxWidth: 500, maxHeight: 900),
                       decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                       child: _selectedGame == 'target_shooter' 
                          ? TargetShooterGame(
                              onWin: () {},
                              onClose: _stopGame,
                            )
                          : PenaltyKickGame(
                              onWin: () {},
                              onClose: _stopGame,
                            ),
                     )
                   : const Text("PRESS LAUNCH\nTO START", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 30)),
               ),
            ),
          )
        ],
      ),
    );
  }
}
