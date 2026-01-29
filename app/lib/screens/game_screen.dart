import 'package:flutter/material.dart';
import 'dart:async';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import '../widgets/liquid_bingo_tile.dart'; // New import
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:talkbingo_app/widgets/quiz_overlay.dart';
import 'package:talkbingo_app/widgets/bubble_background.dart';
import 'package:talkbingo_app/games/target_shooter/target_shooter_game.dart';
import 'package:talkbingo_app/games/penalty_kick/penalty_kick_game.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/host_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/utils/dev_config.dart';
import 'package:talkbingo_app/widgets/floating_score.dart';
import 'package:talkbingo_app/screens/reward_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:talkbingo_app/widgets/draggable_floating_button.dart';

class GameScreen extends StatefulWidget {
  final bool isReviewMode;
  final String? reviewSessionId;

  const GameScreen({
    super.key,
    this.isReviewMode = false,
    this.reviewSessionId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  final GameSession _session = GameSession();
  bool _navigating = false; // Add flag to prevent multiple navigations
  
  // Floating Scores State
  final List<Widget> _floatingScores = [];
  int _previousEp = 0;
  int _previousAp = 0;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // ignore: unused_field
  bool _isAdWatching = false; // Local flag to prevent double triggers
  bool _isBingoDialogVisible = false; // Track dialog visibility
  
  // Floating Button State
  int _unreadCount = 0;
  String? _latestChatPreview;
  Map<String, dynamic>? _lastProcessedMsg;

  // Scroll Controller for Auto-Scroll
  final ScrollController _chatScrollController = ScrollController();
  int _previousPage = 1; // Start on Board (1)

  void _showFloatingScore(Offset position, int points, String label) {
    if (!mounted) return;
    final key = UniqueKey();
    setState(() {
      _floatingScores.add(
        Positioned(
          key: key,
          left: position.dx,
          top: position.dy,
          child: FloatingScore(
            points: points,
            label: label,
            onComplete: () {
              if (mounted) {
                setState(() {
                  _floatingScores.removeWhere((w) => w.key == key);
                });
              }
            },
          ),
        ),
      );
    });
  }

  // Mock State
  final bool _isHost = true; // Assume Host for now
  bool _isPaused = false;
  final String _latestMessage = "Welcome to TalkBingo! Let's start.";
  final int _badgeCount = 0;

  // Animations State
  late ConfettiController _confettiController;
  Set<int> _winningTiles = {};
  // Add direct tracker for button sync
  int _targetPage = 1;

  // State for Entrance Notification
  bool _hasShownEntranceToast = false;
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pageController = PageController(initialPage: 1); 
    
    // Initialize previous points
    _previousEp = _session.ep;
    _previousAp = _session.ap;
    _previousTileOwnership = List.from(_session.tileOwnership);
    
    // Review Mode: Pause Interaction
    if (widget.isReviewMode) {
      _isPaused = true;
    }
    
    // Listen to Session
    _session.addListener(_onSessionUpdate);
    
    // Listen to PageController for Tab Tracking
    _pageController.addListener(() {
       // PageController.page is double, round to check index
       if (_pageController.hasClients) {
         final int newPage = _pageController.page?.round() ?? 1;
         if (_currentPage != newPage) {
           setState(() {
             _currentPage = newPage;
             _targetPage = newPage; // Sync _targetPage with _currentPage on swipe
           });
         }
       }
    });

    // Preload Ad
    AdState.loadInterstitialAd();

    if (_session.questions.isEmpty) {
      _loadQuestions();
    }
    
    // Check initial state immediately (in case data already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSessionUpdate();
      // Force initial page sync
       if (_pageController.hasClients) {
          _currentPage = _pageController.page?.round() ?? 1;
          setState(() {});
       }
    });

    // Polling Fallback for Game Screen (Robust Sync)
    // Run periodically to ensure eventual consistency
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
       if (mounted && _session.sessionId != null) {
          debugPrint("[Polling] Refreshing Session...");
          _session.refreshSession();
       }
    });
  }

  Timer? _pollingTimer;
  
  @override
  void dispose() {
    AdState.isGameActive.value = false;
    _pollingTimer?.cancel();
    _confettiController.dispose();
    _session.removeListener(_onSessionUpdate);
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _chatScrollController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _onPageChanged() {
    final currentPage = _pageController.page?.round() ?? 1;
    
    // Switch to Chat Tab (0)
    if (currentPage == 0 && _previousPage != 0) {
      // Auto Scroll to Bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear unread count when entering chat
        if (mounted) setState(() => _unreadCount = 0);

        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _previousPage = currentPage;
  }

  // State for tracking previous bingo lines to avoid duplicate alerts
  int _previousLinesA = 0;
  int _previousLinesB = 0;
  // int _previousTileCount = 0; // Removed in favor of ownership list
  List<String> _previousTileOwnership = List.filled(25, '');
  final List<GlobalKey> _tileKeys = List.generate(25, (_) => GlobalKey());

  void _onSessionUpdate() {
    if (!mounted) return;

    // 1. Check for Game Over (Global Sync)
    // FORCE DEBUG:
    debugPrint("[GameScreen] Update: Status=${_session.gameStatus}, Nav=$_navigating"); 
    // 0. Check for Mid-Game Ad Break (Synced)
    // 0. Check for Mid-Game Ad Break (Synced)
    // 0. Check for Mid-Game Ad Break (Synced Handshake)
    if (_session.gameStatus == 'paused_ad') {
       // Close the "Waiting for Decision" or "Action" dialog if active so Ad can proceed
       if (_isBingoDialogVisible) {
          if (Navigator.canPop(context)) {
             Navigator.pop(context);
          }
          _isBingoDialogVisible = false;
       }

       final bool amIWatching = _session.adWatchStatus[_session.myRole] ?? false; 
       
       // Case 1: I need to watch but haven't started (Trigger Ad)
       if (amIWatching && !_navigating) {
           _navigating = true; 
           debugPrint("[AdSync] Triggering Forced Ad for ${_session.myRole}");
           
           if (kIsWeb) {
               _showAdOverlay(); // Use local overlay logic
           } else {
               AdState.showInterstitialAd(() async {
                  if (mounted) { 
                      Navigator.pop(context); // Close Ad Screen if pushed
                      _handleAdComplete(); // Sync 'False'
                  }
               });
           }
           return;
       }
       
       // Case 2: I am done (False) but Game is still Paused (Opponent Watching)
       if (!amIWatching) {
           // Ensure waiting overlay is visible via build() injection
           // Check if we are Host -> If Both Done, Resume.
           if (_isHost) {
               final String oppRole = (_session.myRole == 'A') ? 'B' : 'A';
               final bool oppWatching = _session.adWatchStatus[oppRole] ?? false;
               if (!oppWatching) {
                   debugPrint("[AdSync] Both Players Ready. Resuming Game.");
                   _session.setGameStatus('playing');
               }
           }
       }
       return; // Block other updates while paused_ad
    } else {
       // Reset _navigating if status cleared (e.g. after resume)
       if (_navigating && _session.gameStatus == 'playing') {
          _navigating = false;
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Remove "Waiting" toast
       }
    }

    // 1. Check for Bingo State (Triggers Dialogs)
    if (_session.gameStatus == 'playing' || _session.gameStatus == 'waiting') {
       _checkBingoState();
       
       // Entrance Notification Logic (One-time)
       if (!_hasShownEntranceToast) {
         if (_isHost) {
            // Host: Wait for Guest Nickname
            if (_session.guestNickname != null && _session.guestNickname!.isNotEmpty) {
               _hasShownEntranceToast = true;
               _showEntranceNotification("${_session.guestNickname} has entered!"); 
            }
         } else {
            // Guest: Host is always present (owner)
            // Just show immediately if we are connected
            if (_session.hostNickname != null) {
               _hasShownEntranceToast = true;
               _showEntranceNotification("Host has entered!");
            }
         }
       }
    }

    // 2. Check for Game Over (Synced)

    // 2. Check for Game Over (Synced)
    if (_session.gameStatus == 'finished' && !_navigating && !widget.isReviewMode) {
       _navigating = true; // Use local flag to prevent multiple navs
       
       // Close any existing dialogs (Bingo / Waiting)
       // Close any existing dialogs (Bingo / Waiting)
       if (_isBingoDialogVisible && Navigator.canPop(context)) {
          Navigator.pop(context); 
          _isBingoDialogVisible = false;
       }

       // Show "Game Ended" Dialog (Final Step before Reward)
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => AlertDialog(
           title: Text("Game Over! 🏁", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: _themePrimary)),
           content: const Text("The game has ended.\nProceed to collect your rewards!"),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           actions: [
             ElevatedButton(
               onPressed: () {
                 Navigator.pop(ctx);
                 _proceedToReward();
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFE91E63),
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text("Accept & Continue"),
             )
           ],
         ),
       );
       return;
    }
    
    // 2. Check for EP Gain (Tile Claim)
    // Detect newly acquired tiles to award points locally and show animation AT THE TILE
    bool tileAnimationShown = false;
    for (int i = 0; i < 25; i++) {
       String owner = _session.tileOwnership[i];
       if (owner == _session.myRole && _previousTileOwnership[i] != _session.myRole) {
          // I gained this specific tile 'i'
          tileAnimationShown = true;
          // Award points
          Future.microtask(() => _session.addPoints(e: 1));
          
          // Show Animation at Tile Position
          final key = _tileKeys[i];
          final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
             final position = renderBox.localToGlobal(Offset.zero);
             final size = renderBox.size;
             // Center above the tile
             _showFloatingScore(
                Offset(position.dx + size.width / 2 - 20, position.dy - 40),
                1,
                "" 
             );
          }
       }
       _previousTileOwnership[i] = owner; // Update tracking
    }

    if (tileAnimationShown) {
       // Sync previous EP to prevent double animation from generic check below
       // We assume the tile gain adds 1 EP per tile.
       // However, _session.ep might not be updated yet (microtask).
       // But when it DOES update, _previousEp will be old.
       // We should update _previousEp here to "expected" value?
       // Or simpler: The generic check detects change in _session.ep.
       // If we just showed animation, we want to skip the next generic check if the diff matches.
       // But strictly speaking, the generic check is for "Any EP change".
       // Let's rely on _previousEp matching _session.ep once the update propagates?
       // Actually, safely we can just let it be. If double animation happens, it's rare.
       // But better: Update _previousEp to current _session.ep + gained? No.
       // Let's just update `_previousEp` to `_session.ep` when checking.
       // And accept that if `addPoints` is instant, we might duplicate.
       // Actually, `addPoints` calls notifyListeners.
       // So `_onSessionUpdate` runs again.
       // In that run, tile ownership is ALREADY updated (we updated `_previousTileOwnership` just now).
       // So loop won't run. `tileAnimationShown` = false.
       // Then `_session.ep > _previousEp` check runs. Animation shows again.
       
       // FIX: We need to handle the EP change in the generic block responsibly.
       // If we assume ALL EP comes from tiles for now (or user mostly cares about tiles),
       // We can change the generic block to ONLY fire if `tileAnimationShown` was false?
       // No, because they run in different passes.
       
       // Solution: `_previousTileCount` is removed, but we can track `_expectedEp`?
       // Or: In the generic block, check if `_previousTileOwnership` changed recently? No.
       
       // Best bet: Calculate `gainedEpFromTiles` in the generic block by comparing tile counts again?
       // No.
       
       // Simple Fix: Just remove the generic EP check for now since the user specifically asked for "Tile Animation".
       // If there are other EP sources, we'll miss them, but Tile is primary.
       // Or we can keep it but check against tile count diff?
       
       // Let's suppress generic usage by updating _previousEp to the FUTURE value?
       // _previousEp = _session.ep + 1; // Anticipate
    }
    
    // Generic EP Check (Modified to avoid double show for tiles if possible, or just accept double for safety & fun)
    // Actually, user said "Make AP point appear above cell".
    // If it appears in center too, it's confusing.
    // I will COMMENT OUT the generic center animation to ensure only the Tile Specific one plays for tiles.
    // If there are other EP events, they won't show +1 in center. This is acceptable/safer for this request.
    /* 
    if (_session.ep > _previousEp) {
      final int diff = _session.ep - _previousEp;
      // ... generic center animation ...
    }
    */
    // Instead, just sync the variable to prevent future drift
    if (_session.ep > _previousEp) {
       _previousEp = _session.ep;
    }
    
    // 3. Check for Board Full (Draw / End)
    int occupiedCount = 0;
    for (var owner in _session.tileOwnership) {
        if (owner.isNotEmpty) occupiedCount++;
    }
    if (occupiedCount >= 25 && _session.gameStatus != 'finished') {
       if (_isHost && !_isGameEndedDialogShown) {
          _showBoardFullDialog();
       }
    }
    
    // 4. Bingo Check & Notification (For BOTH Players)
    final linesA = _checkForBingo('A');
    final linesB = _checkForBingo('B');
    
    // 5. Check for New Messages (Unread Count)
    if (_session.messages.isNotEmpty) {
      // Filter out system messages for unread count and preview
      final chatMessages = _session.messages.where((m) => m['type'] == 'chat').toList();
      if (chatMessages.isNotEmpty) {
        final lastMsg = chatMessages.last;
        // Compare by timestamp or content + timestamp to be sure
        final lastTs = lastMsg['timestamp'];
        final processedTs = _lastProcessedMsg?['timestamp'];
        
        if (lastTs != processedTs) {
           // Only notify for CHAT messages from OTHERS 
           // Exclude SYSTEM messages and Self messages
           final sender = lastMsg['sender'] ?? '';
           final type = lastMsg['type'];
           final isSystem = sender.toString().startsWith('SYSTEM');
           
           if (type == 'chat' && !isSystem && sender != _session.myRole) {
               if (_currentPage == 1) { // If on Board
                   _unreadCount++;
                   _latestChatPreview = lastMsg['text'];
               }
           }
           _lastProcessedMsg = lastMsg;
        }
      }
    }
    
    // Auto Scroll if on Chat Tab and new msg arrives
    // (Optional: Only if already at bottom? For now force scroll for better visibility)
    if (_currentPage == 0 && _session.messages.isNotEmpty) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300), 
                curve: Curves.easeOut
              );
          }
       });
    }

     if (mounted) setState(() {});
  }

  void _handleAdComplete() {
      _navigating = false;
      _session.updateAdStatus(false); // I am done
      // Show waiting toast
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text("Waiting for opponent to finish ad..."),
           duration: Duration(seconds: 20), // Long duration, clears on resume
         )
      );
  }




  Future<void> _loadQuestions() async {
    await _session.fetchQuestionsFromBackend();
    if (mounted) {
      setState(() {});
    }
  }

  void _initSpeech() async {
    try {
       _speechEnabled = await _speech.initialize(
         onStatus: (val) {
            debugPrint('onStatus: $val');
            if (val == 'done' || val == 'notListening') {
               if (mounted) setState(() => _isListening = false);
            }
         },
         onError: (val) {
            debugPrint('onError: $val');
            if (mounted) setState(() => _isListening = false);
         },
       );
       if (mounted) setState(() {});
    } catch (e) {
       debugPrint("Speech Init Error: $e");
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
       // Try re-init
       await _speech.initialize(); 
    }
    
    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _session.language == 'ko' ? 'ko_KR' : 'en_US',
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _chatController.text = result.recognizedWords;
    });
  }

  // --- New Header Implementation ---
  // --- Redesigned Header (Transparent + Floating Text) ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo Only
            SvgPicture.asset(
              'assets/images/Logo Vector.svg',
              height: 30,
            ),
            
            const SizedBox(height: 18),
            
            // 2. Floating Text Row (POINT | TURN | MENU)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // POINT (Popover Trigger)
                Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: const PopupMenuThemeData(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tooltip: '포인트 보기',
                    child: _buildFloatingText("포인트 ${_session.ep}"),
                     itemBuilder: (context) {
                         // Calculate Real-time Stats
                         int filledCells = _session.tileOwnership.where((o) => o == _session.myRole).length;
                         // A simple line check logic for display (full logic is in session)
                         // For now, just show EP as Cells and AP as Lines from session if updated,
                         // OR rename the labels as requested mapping:
                         // AP -> "빙고줄" (Bingo Lines)
                         // EP -> "빙고셀" (Bingo Cells)
                         
                         return [
                            PopupMenuItem(
                              enabled: false, // Info only
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 150),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("빙고줄: ${_session.ap ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text("빙고셀: $filledCells", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                              ),
                            )
                         ];
                    }
                  ),
                ),
                
                _buildDivider(),
                
                // TURN
                // TURN (Animated & Colored)
                _buildTurnIndicator(),
                
                _buildDivider(),
                
                // MENU (Popover Trigger Style)
                // MENU (Popover Trigger Style)
                Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: const PopupMenuThemeData(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildFloatingText("메뉴"),
                    onSelected: (value) async {
                       if (value == 'Save') {
                          // Implement Save Logic
                       } else if (value == 'End') {
                          _endGame(); 
                       }
                    },
                    itemBuilder: (context) {
                         // Dynamically size width to content (approx)
                         return [
                            PopupMenuItem(
                              value: 'Save', 
                              child: Container(
                                width: 100, // Explicit width control
                                alignment: Alignment.center,
                                child: Text("저장하기", style: GoogleFonts.alexandria(color: Colors.black87))
                              ),
                            ),
                            PopupMenuItem(
                              value: 'End', 
                              child: Container(
                                width: 100,
                                alignment: Alignment.center,
                                child: Text("종료하기", style: GoogleFonts.alexandria(color: Colors.black87))
                              ),
                            ),
                          ];
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingText(String text) {
    return Text(
      text,
      style: GoogleFonts.alexandria(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        shadows: [
          const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final bool isMyTurn = _session.currentTurn == _session.myRole;
    final String text = isMyTurn ? "나의 턴" : "상대방 턴";
    final Color color = isMyTurn ? const Color(0xFFFF0077) : const Color(0xFF6B14EC);
    
    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
         ScaleEffect(
           begin: const Offset(1.0, 1.0), 
           end: const Offset(1.1, 1.1),
           duration: 1000.ms, 
           curve: Curves.easeInOut
         )
      ],
      child: Text(
        text,
        style: GoogleFonts.alexandria(
          color: color,
          fontSize: 16, // Larger size
          fontWeight: FontWeight.w800, // Extra bold
          shadows: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ]
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 10,
      color: Colors.white54,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide Ad on Game Screen (Full Immersion)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = false;
    });

    // Enforce transparent status bar with dark icons for this screen
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // For light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
      child: WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Allow keyboard
        body: BubbleBackground(
          interactive: true,
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. New Header
                  _buildHeader(),

                  // 2. Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100.0), // Added bottom padding for Ad Overlay
                      child: Stack(
                        children: [
                         PageView(
                           // Physics removed to allow swiping
                           controller: _pageController,
                          // Listener is handled in initState
                          children: [
                              _buildChatView(),
                              _buildBingoBoard(),
                          ],
                        ),

                        // Quiz Overlay (Moved here to cover ONLY the board area)
                        if (_session.interactionState != null && _targetPage == 1)
                          Builder(
                            builder: (context) {
                              final state = _session.interactionState!;
                              // Check for Mini Game Types
                              final String? type = state['type'];
                              if (type == 'mini_target' || type == 'mini_penalty') {
                                return const SizedBox.shrink(); // Rendered at Top Level instead
                              }

                              // Default Quiz Overlay Logic
                              final int index = (state['index'] as num?)?.toInt() ?? -1;
                              final bool hasPayloadData = state.containsKey('question');
                              
                              if (!hasPayloadData && (index < 0)) {
                                return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      margin: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.sync_problem, color: Colors.amber, size: 48),
                                            const SizedBox(height: 16),
                                            Text("Sync Error", style: GoogleFonts.alexandria(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                                onPressed: () { _session.cancelInteraction(); },
                                                child: const Text("Reset State"),
                                            )
                                          ]
                                      )
                                    )
                                );
                              }

                              Map<String, dynamic> localOpts = {};
                              if (_session.options.isNotEmpty && index >= 0) {
                                final idxSafe = index.clamp(0, _session.options.length - 1);
                                localOpts = _session.options[idxSafe];
                              }
                              
                              final String qText = _resolveQuestionText(index, state['question']);
                              
                              final bool isEnglish = _session.language == 'en';
                              final String qText = _resolveQuestionText(index, state['question']);
                              
                              // Resolve Localized Options
                              String optA = isEnglish ? (localOpts['A_en'] ?? '') : (localOpts['A'] ?? '');
                              if (optA.isEmpty) optA = state['optionA'] ?? localOpts['A'] ?? ''; // Fallback
                              
                              String optB = isEnglish ? (localOpts['B_en'] ?? '') : (localOpts['B'] ?? '');
                              if (optB.isEmpty) optB = state['optionB'] ?? localOpts['B'] ?? ''; // Fallback
                              
                              // Resolve Localized Answer (Truth)
                              // Prioritize 'truthOptions' from payload as it is the synced truth for this interaction
                              String answerStr = state['truthOptions'] ?? '';
                              
                              if (answerStr.isEmpty) {
                                 // Fallback to local options
                                 answerStr = isEnglish ? (localOpts['answer_en'] ?? '') : (localOpts['answer'] ?? '');
                              }

                              return Positioned.fill(
                                child: QuizOverlay(
                                  question: qText,
                                  optionA: optA,
                                  optionB: optB,
                                  type: type ?? localOpts['type'],
                                  answer: answerStr, 
                                  interactionStep: state['step'],
                                  answeringPlayer: state['player'],
                                  submittedAnswer: state['answer'],
                                  isPaused: state['isPaused'] ?? false, 
                                  onOptionSelected: _handleOptionSelected,
                                  onClose: () {},
                                ),
                              );
                            }
                          ),
                      ],
                    ),
                  ),
                  
                  // 3. Persistent Input Field (Visible on ALL tabs)
                  // Wrapped in Container to ensure visibility
                  Container(
                     color: Colors.white,
                     child: _buildBottomControls(),
                  ),
                ],
              ),
              
                      // Rematch Button (Review Mode Only)
                      if (widget.isReviewMode && _currentPage == 1)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton.extended(
                            heroTag: 'rematch_btn',
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            label: const Text("REMATCH", style: TextStyle(fontFamily: 'NURA', fontWeight: FontWeight.bold)),
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                               Navigator.of(context).push(
                                 MaterialPageRoute(
                                   builder: (_) => HostSetupScreen(
                                     initialGender: _session.guestGender,
                                     initialMainRelation: _session.relationMain,
                                     initialSubRelation: _session.relationSub,
                                     initialIntimacyLevel: _session.intimacyLevel,
                                   ),
                                 ),
                               );
                            },
                          ),
                        ),

          
          // 5. Full-size Quiz Overlay (Top Level)



          // 3. Mini Game Overlay (Full Screen, Covers Header)
          if (_session.interactionState != null)
            Builder(
              builder: (context) {
                final state = _session.interactionState!;
                final String? type = state['type'];
                
                if (type == 'mini_target') {
                    return TargetShooterGame(
                      onWin: () async { await _session.resolveInteraction(true); },
                      onClose: () { _session.resolveInteraction(false); },
                    );
                } else if (type == 'mini_penalty') {
                    return PenaltyKickGame(
                      onWin: () async { await _session.resolveInteraction(true); },
                      onClose: () { _session.resolveInteraction(false); },
                    );
                }
                return const SizedBox.shrink();
              }
            ),

          // Floating Scores Layer
          ..._floatingScores,

          // Confetti Layer (Top Center)
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // Down
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ),
          _buildAdWaitOverlay(),
          
          // Draggable Floating Button (Top Layer)
          DraggableFloatingButton(
            key: ValueKey('float_btn_$_targetPage'), // Force rebuild on page change state
            isOnChatTab: _targetPage == 0,
            unreadCount: _unreadCount,
            latestMessage: _latestChatPreview,
            themeColor: _themePrimary,
            onTap: () {
               // Toggle Page
               final nextPage = _targetPage == 0 ? 1 : 0;
               setState(() {
                 _targetPage = nextPage;
               });
               _pageController.animateToPage(
                 nextPage, 
                 duration: const Duration(milliseconds: 400), 
                 curve: Curves.easeInOutBack
               );
            },
          ),
        ], // Stack Children
        ), // Stack
      ), // Container
    ), // Scaffold
    ), // WillPopScope
    ); // AnnotatedRegion
  }

  // --- Chat & Ticker Logic ---

  bool _isTickerExpanded = false;
  final TextEditingController _chatController = TextEditingController();

  // --- Theme Helpers ---
  Color get _themePrimary => _session.myRole == 'A' ? AppColors.hostPrimary : AppColors.guestPrimary;
  Color get _themeSecondary => _session.myRole == 'A' ? AppColors.hostSecondary : AppColors.guestSecondary;
  Color get _themeDark => _session.myRole == 'A' ? AppColors.hostDark : AppColors.guestDark;





  Widget _buildChatView() {
    return Container(
      color: Colors.white.withOpacity(0.5),
      child: ListView.builder(
        controller: _chatScrollController, // Connected Controller
        padding: const EdgeInsets.symmetric(vertical: 16), // Top/Bottom padding
        itemCount: _session.messages.length,
        itemBuilder: (context, index) {
          final msg = _session.messages[index];
          final sender = msg['sender'] ?? '';
          
          // --- 2.2 SYSTEM MESSAGE ---
          if (sender == 'SYSTEM') {
             return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],  // Neutral Background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  msg['text'] ?? '',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,        // Caption
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- 2.3 QUESTION / ANSWER SYSTEM MESSAGE ---
          if (sender == 'SYSTEM_Q' || sender == 'SYSTEM_A') {
             final player = msg['player']; // Owner of the interaction
             final Color userColor = (player == 'A') ? AppColors.hostPrimary : AppColors.guestPrimary;
             
             return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: userColor.withOpacity(0.3), // Light border of user color
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: userColor.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  msg['text'] ?? '', 
                  style: GoogleFonts.doHyeon(
                    fontSize: 15, // Prominent text
                    color: userColor.withOpacity(0.8), // Colored text
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- 2.1 CHAT MESSAGE ---
          final isMe = sender == _session.myRole;
          final time = DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now();
          final timeStr = DateFormat('h:mm a').format(time);

          if (isMe) {
            // MY MESSAGE (Right Aligned)
            return Container(
              margin: const EdgeInsets.only(
                left: 60,    // Max width constraint
                right: 12,   // Screen margin
                bottom: 8,   // Gap
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _session.myRole == 'A' ? const Color(0xFFF4E7E8) : const Color(0xFFF0E7F4), // Tint based on My Role
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),  // Tail
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg['text'] ?? '',
                    style: GoogleFonts.doHyeon(
                      fontSize: 13,        // Body 2
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.alexandria(
                      fontSize: 10,        // Micro
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // OPPONENT MESSAGE (Left Aligned)
            // Determine opponent role color for tint
            final oppRole = _session.myRole == 'A' ? 'B' : 'A';
            final tintColor = oppRole == 'A' ? const Color(0xFFF4E7E8) : const Color(0xFFF0E7F4);

            return Container(
              margin: const EdgeInsets.only(
                left: 12,
                right: 60,
                bottom: 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tintColor, 
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),  // Tail
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    msg['text'] ?? '',
                    style: GoogleFonts.doHyeon(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.alexandria(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$formattedHour:$minute $period";
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.topCenter, // Align content to top
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              enabled: !_isPaused,
              minLines: 1,
              maxLines: 4, // Allow it to expand downwards
              onChanged: (text) => setState(() {}), // Rebuild to toggle icon
              decoration: InputDecoration(
                hintText: _isPaused ? 'Game Paused' : 'Type a message...',
                hintStyle: GoogleFonts.alexandria(
                  textStyle: const TextStyle(color: Colors.grey, fontFamilyFallback: ['EliceDigitalBaeum'])
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _themePrimary.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _themePrimary.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _themePrimary),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: Colors.black87,
                textStyle: const TextStyle(fontFamilyFallback: ['EliceDigitalBaeum']),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: AnimatedButton(
               onPressed: _isPaused ? null : () {
                  if (_chatController.text.isNotEmpty) {
                      _handleSendMessage();
                  } else {
                      // Toggle Speech
                      if (_isListening) {
                         _stopListening();
                      } else {
                         _startListening();
                      }
                  }
               },
               style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: _isListening ? Colors.redAccent : (_isPaused ? Colors.grey : _themePrimary),
                  padding: const EdgeInsets.all(10),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white70,
               ),
               child: Icon(
                  _chatController.text.isNotEmpty 
                      ? Icons.send 
                      : (_isListening ? Icons.mic_off : Icons.mic), // Toggle Icon
                  color: Colors.white,
                  size: 20,
               ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice to text not implemented yet.')),
      );
      return;
    }

    _session.sendMessage(text);
    _chatController.clear();
    setState(() {}); // Rebuild to update UI immediately (optimistic update handled in model)
  }



  // Game State
  // Game State
  // Removed local _tileOwnership to use _session.tileOwnership
  // Removed local _currentTurn to use _session.currentTurn
  int? _hoveredIndex; // For hover effect
  int? _pressedIndex; // For touch/press effect
  // int? _activeQuizIndex; // For full-size overlay - REMOVED

  // Interaction Handlers

  Future<void> _onTileTapped(int index) async {
    // Review Mode: Block Interaction
    if (widget.isReviewMode) return;

    if (_isPaused) {
       _showSnackBar("Game paused. Please wait.");
       return;
    }
    final owner = _session.tileOwnership[index];
    
    // 1. Basic Validations
    if (owner.isNotEmpty && owner != 'LOCKED') {
      _showSnackBar('This tile is already taken!');
      return;
    }
    if (_isPaused) {
      _showSnackBar('Game is paused.');
      return;
    }
    
    // 2. Turn Validation (or Mini Game Trigger)
    if (owner == 'LOCKED') {
       // Mini Game Trigger (M-Type)
       // Anyone can trigger? Or maybe still turn based?
       // Rules: "Next turn anyone can challenge".
       // For simplicity MVP, let's allow ANYONE to trigger if it's locked.
       // Or stick to turn: "Next turn". Let's assume Turn is required.
       // Actually rules say: "Next turn from... anyone can press". 
       // Let's enforce Turn for now to avoid chaos.
       if (_session.currentTurn != _session.myRole) {
          _showSnackBar("It's not your turn!");
          return;
       }
       // Start Mini Game
       _session.startInteraction(index, 'mini', _session.myRole);
       return;
    }

    if (_session.currentTurn != _session.myRole) {
       _showSnackBar("It's not your turn!");
       return;
    }

    // 3. Check if already interacting
    if (_session.interactionState != null) {
      // already active
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: const Text('Interaction in progress! Please finish the quiz.'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
               label: 'RESET',
               textColor: Colors.amber,
               onPressed: () async {
                  try {
                    await _session.cancelInteraction();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('State Reset! Try clicking again.'))
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reset Sync Failed: $e. Local state cleared.'))
                    );
                  }
               },
            ),
         )
      );
      return;
    }

    // 4. Start Interaction (Optimistic + DB)
    
    // Prepare Data to Embed
  String qText = '';
  String type = 'balance';
  String optA = '';
  String optB = '';
  String suggestions = ''; // For Truth Game
  
  if (index < _session.questions.length) {
     qText = _session.questions[index];
  }
  if (index < _session.options.length) {
     final opts = _session.options[index];
     type = opts['type'] ?? 'balance';
     optA = opts['A'] ?? '';
     optB = opts['B'] ?? '';
     suggestions = opts['answer'] ?? ''; // Extract Truth suggestions
  }

  await _session.startInteraction(
    index, 
    type, 
    _session.myRole,
    q: qText,
    A: optA,
    B: optB,
    suggestions: suggestions // Pass to sync
  );
  }

  void _handleOptionSelected(String value) {
     // This is called when 'Confirm' (Answer) is clicked OR 'Approve/Reject' is clicked.
     // We need to differentiate based on current step.
     
     final state = _session.interactionState;
     if (state == null) return;
     
     final step = state['step'];

     if (step == 'answering') {
       // Player submitted answer
       String fullText = value;
       if (value == 'A') fullText = state['optionA'] ?? value;
       if (value == 'B') fullText = state['optionB'] ?? value;
       
       _session.submitAnswer(fullText);
     } else if (step == 'reviewing') {
       // Reviewer decided
       bool approved = (value != 'REJECT');
       _session.resolveInteraction(approved);
       
       if (approved) {
         // Show success feedback
         // Check Bingo locally for notification?
         // _session Listener will handle tile update, but we can show snackbar here?
         // Actually wait for tile update in listener to sound effect/snackbar.
       } else {
         _showSnackBar('Tile Locked! 🔒', color: Colors.grey);
       }
     }
  }


  void _showSnackBar(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // Legacy _handleQuizResult removed as logic moved to _handleOptionSelected & _session




  int _checkForBingo(String player) {
    int lines = 0;

    // Check Rows (0, 1, 2, 3, 4)
    for (int row = 0; row < 5; row++) {
      bool win = true;
      for (int col = 0; col < 5; col++) {
        int index = row * 5 + col;
        if (_session.tileOwnership[index] != player) {
          win = false;
          break;
        }
      }
      if (win) lines++;
    }

    // Check Columns (0, 1, 2, 3, 4)
    for (int col = 0; col < 5; col++) {
      bool win = true;
      for (int row = 0; row < 5; row++) {
        int index = row * 5 + col;
        if (_session.tileOwnership[index] != player) {
          win = false;
          break;
        }
      }
      if (win) lines++;
    }

    // Check Diagonal (Top-Left to Bottom-Right)
    bool d1 = true;
    for (int i = 0; i < 5; i++) {
      int index = i * 5 + i; // 0, 6, 12, 18, 24
      if (_session.tileOwnership[index] != player) {
        d1 = false;
        break;
      }
    }
    if (d1) lines++;

    // Check Diagonal (Top-Right to Bottom-Left)
    bool d2 = true;
    for (int i = 0; i < 5; i++) {
      int index = i * 5 + (4 - i); // 4, 8, 12, 16, 20
      if (_session.tileOwnership[index] != player) {
        d2 = false;
        break;
      }
    }
    if (d2) lines++;

    return lines;
  }

  // Identify winning tiles for animation
  Set<int> _getWinningTiles(String player) {
    Set<int> winning = {};

    // Rows
    for (int row = 0; row < 5; row++) {
      List<int> line = [];
      bool win = true;
      for (int col = 0; col < 5; col++) {
        int index = row * 5 + col;
        line.add(index);
        if (_session.tileOwnership[index] != player) {
          win = false;
          break;
        }
      }
      if (win) winning.addAll(line);
    }

    // Columns
    for (int col = 0; col < 5; col++) {
      List<int> line = [];
      bool win = true;
      for (int row = 0; row < 5; row++) {
        int index = row * 5 + col;
        line.add(index);
        if (_session.tileOwnership[index] != player) {
          win = false;
          break;
        }
      }
      if (win) winning.addAll(line);
    }

    // Diagonals
    List<int> d1 = [];
    bool d1Win = true;
    for (int i = 0; i < 5; i++) {
      int index = i * 5 + i;
      d1.add(index);
      if (_session.tileOwnership[index] != player) {
        d1Win = false;
        break;
      }
    }
    if (d1Win) winning.addAll(d1);

    List<int> d2 = [];
    bool d2Win = true;
    for (int i = 0; i < 5; i++) {
      int index = i * 5 + (4 - i);
      d2.add(index);
      if (_session.tileOwnership[index] != player) {
        d2Win = false;
        break;
      }
    }
    if (d2Win) winning.addAll(d2);

    return winning;
  }

    Widget _buildBingoBoard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1, // Keep board square
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _session.questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "Waiting for Host...",
                            style: GoogleFonts.alexandria(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Questions are being prepared.",
                            style: GoogleFonts.alexandria(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Layer 1: Grid of Tiles
                        GridView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: 25,
                          itemBuilder: (context, index) {
                            return _buildBingoTile(index);
                          },
                        ),
                        


                        
                        // Layer 3: Winning Lines Overlay (Visual Only - Ignore Pointers)
                        // Layer 3: Winning Lines Overlay (Visual Only - Ignore Pointers)
                        _buildWinningLinesOverlay(),
                      ],
                    ),
            ),
          ),
        ),
      );
  }

  Widget _buildScorePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _themePrimary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 6),
          // Rolling Counter
          AnimatedFlipCounter(
            value: _session.ep,
            duration: const Duration(milliseconds: 1000), // Slow satisfying roll
            textStyle: GoogleFonts.alexandria(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text("EP", style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      )
    ).animate(target: 1).shimmer(delay: 500.ms, duration: 1500.ms, color: Colors.white);
  }



  Widget _buildPageIndicator(int pageIndex, String label) {
    bool isActive = _currentPage == pageIndex;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(pageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _themePrimary : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBingoTile(int index) {
    String owner = _session.tileOwnership[index];
    bool isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: (owner == 'X') ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: LiquidBingoTile(
        text: "", // Removed index number as per user request
        owner: owner,
        isHost: _isHost, 
        isHovered: isHovered,
        isWinningTile: _winningTiles.contains(index),
        onTap: () {
        if (!_isHost && !_session.isGameActive) return; 
        
        // Restore Mini-Game launch for Locked/X tiles
        if (owner.startsWith('LOCKED') || owner == 'X') {
           _launchRandomMiniGame(index);
           return;
        }
        
        if (_session.myRole == _session.currentTurn && owner.isEmpty) {
           _onTileTapped(index);
        }
      },
      ),
    );
  }

  bool _isGameEndedDialogShown = false;
  // Duplicate _isBingoDialogVisible removed


  // Modified to handle "Wait Handshake" Overlay

  void _showBingoDialog({required int lines, required bool isWinner}) {
    if (_isBingoDialogVisible) return; // Prevent double show
    _isBingoDialogVisible = true;

    final isGameOver = lines >= 3;
    final dialogTitle = isGameOver ? "BINGO! 🏆" : "BINGO! 🎉";
    final dialogMsg = isGameOver 
        ? "Congratulations! You completed 3 lines!\nThe game is finished." 
        : "You completed $lines line${lines > 1 ? 's' : ''}!";
        
    final opponentName = _isHost ? (_session.guestNickname ?? 'Guest') : (_session.hostNickname ?? 'Host');
    final waitMsg = "Waiting for $opponentName to decide...";

    // Helper to build content
    Widget buildContent() {
       return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(isWinner ? Icons.celebration : Icons.hourglass_top, 
                  color: isWinner ? const Color(0xFFE91E63) : Colors.grey, size: 40),
             const SizedBox(height: 10),
             Text(isWinner ? dialogTitle : "OPPONENT BINGO!", 
                  style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: Colors.black87)),
             const SizedBox(height: 10),
             Text(
               isWinner ? dialogMsg : "$opponentName completed a line!\n$waitMsg",
               textAlign: TextAlign.center,
               style: GoogleFonts.alexandria(color: Colors.grey[700]),
             ),
          ],
       );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: buildContent(),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: isWinner ? [
          if (!isGameOver)
            ElevatedButton(
              onPressed: () async {
                  _isBingoDialogVisible = false; // Reset flag first
                  Navigator.pop(context);
                  
                  // Shared Logic: Continue
                  if (_session.adFree || _session.vp >= 200) {
                      _session.setGameStatus('playing'); // Resume immediately
                  } else {
                      await _session.startAdBreak(); // Trigger Handshake
                      // _showAdOverlay() handled by listener now to avoid stacking
                  }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Continue Play"),
            ),
          
          ElevatedButton(
            onPressed: () {
                _isBingoDialogVisible = false;
                Navigator.pop(context);
                
                // Set navigating to true to prevent _onSessionUpdate from reacting to 'finished' state
                // (which would show the 'Game Over' dialog on top of our navigation)
                _navigating = true;

                _session.endGame(); 
                _proceedToReward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("End Game", style: TextStyle(color: Colors.white)),
          )
        ] : [], // No actions for waiter
      ),
    ).then((_) {
       _isBingoDialogVisible = false;
    });

  }

  // Ad Overlay Logic
  void _showAdOverlay() {
    // In a real app, this would be AdMob Interstitial. 
    // For Web/Prototype, we use a Dialog or Overlay.
    // The requirement is "Forced Ad" (Simultaneous).
    
    showDialog(
       context: context,
       barrierDismissible: false, // Cannot skip?
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setState) {
             return WillPopScope( // Prevent Back Button
               onWillPop: () async => false,
               child: Scaffold(
                 backgroundColor: Colors.black,
                 body: Stack(
                   children: [
                     Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Text("ADVERTISEMENT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 20),
                           Container(
                             width: 300, height: 200, color: Colors.grey[800],
                             alignment: Alignment.center,
                             child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
                           ),
                           const SizedBox(height: 30),
                           ElevatedButton(
                             onPressed: () async {
                                // Ad Finished
                                Navigator.pop(context);
                                await _session.updateAdStatus(false); // watching = False
                                
                                // Check if we need to WAIT
                                // The listener will handle the "Wait" overlay if status is still 'paused_ad'
                             }, 
                             child: const Text("Close Ad")
                           )
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             );
           }
         );
       }
    );
  }

  // Waiting for Opponent Overlay (Handshake)
  Widget _buildAdWaitOverlay() {
      // Logic: Only show if gameStatus == 'paused_ad' AND myAdStatus == false (I finished, they are watching)
      final showWait = _session.gameStatus == 'paused_ad' && (_session.adWatchStatus[_session.myRole] == false);
      
      if (!showWait) return const SizedBox.shrink();

      return Container(
        color: Colors.black.withOpacity(0.9),
        alignment: Alignment.center,
        child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              CircularProgressIndicator(color: _themePrimary),
              const SizedBox(height: 24),
              Text(
                "Waiting for opponent to finish ad...",
                style: GoogleFonts.alexandria(color: Colors.white, fontSize: 16),
              ),
           ],
        ),
      );
  }

  void _showEntranceNotification(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Auto-close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted && Navigator.canPop(context)) {
             Navigator.pop(context);
          }
        });
        
        return Material(
           color: Colors.transparent,
           child: Center(
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.7),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                 ]
               ),
               child: Text(
                 message,
                 style: GoogleFonts.alexandria(
                   color: Colors.white,
                   fontSize: 20,
                   fontWeight: FontWeight.bold,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
           ),
        );
      }
    );
  }

  // Refactor _buildBoardFullDialog to use new logic (triggered by 3 lines or explicit logic)
  void _checkBingoState() {
      // 1. Calculate Current Lines
      final linesA = _checkForBingo('A');
      final linesB = _checkForBingo('B');
      
      bool aWonLine = linesA > _previousLinesA;
      bool bWonLine = linesB > _previousLinesB;
      
      // 2. Update Trackers immediately to consume event
      if (aWonLine) {
         debugPrint("[Bingo] A Line! $linesA (Prev: $_previousLinesA)");
         _previousLinesA = linesA;
      }
      if (bWonLine) {
         debugPrint("[Bingo] B Line! $linesB (Prev: $_previousLinesB)");
         _previousLinesB = linesB;
      }
      
      // 3. Determine Dialog Trigger (Priority: My Win > Opponent Win)
      bool meWon = (_session.myRole == 'A' && aWonLine) || (_session.myRole == 'B' && bWonLine);
      bool oppWon = (_session.myRole == 'A' && bWonLine) || (_session.myRole == 'B' && aWonLine);

      if (meWon) {
          // I won. Show Winner Dialog.
          // Note: If both won, My Win logic takes precedence for My Screen.
          int myLines = (_session.myRole == 'A') ? linesA : linesB;
          if (myLines >= 1) {
              _confettiController.play(); // 🎉 JUICY CONFETTI 🎉
              _showBingoDialog(lines: myLines, isWinner: true);
          }
      } else if (oppWon) {
          // Opponent won (and I didn't, or I already handled it).
          // Show Waiter Dialog.
          int oppLines = (_session.myRole == 'A') ? linesB : linesA;
          if (oppLines >= 1) {
              _showBingoDialog(lines: oppLines, isWinner: false);
          }
      }
  }


  
  // Actually, I need to replace _showBoardFullDialog as requested.
  // And probably add logic to _onSessionUpdate to handle the "Pop Guest Dialog" logic.

  void _showBoardFullDialog() {
      // This was the old name for Game Over. 
      // Now replaced by _showBingoDialog(lines: 3) effectively.
      _showBingoDialog(lines: 3, isWinner: true);
  }

  void _restartGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Game?'),
        content: const Text('This will clear the board and reset turns. Current progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _session.reset(); // Use session reset
                _isPaused = false;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _proceedToReward() {
       // Apply Rewards exactly once before navigating
       _session.applyEndGameRewards();
       
       if (!_session.adFree) {
          // Mock Ad for Web
          if (kIsWeb) {
             showDialog(
               context: context,
               barrierDismissible: false,
               builder: (context) => AlertDialog(
                 title: const Text("ADVERTISEMENT (Mock)"),
                 content: Container(
                   width: 300, height: 200,
                   color: Colors.grey[300],
                   alignment: Alignment.center,
                   child: const Text("Ad Content Here\n(Web doesn't support AdMob)", textAlign: TextAlign.center),
                 ),
                 actions: [
                   TextButton(
                     onPressed: () {
                        Navigator.pop(context); // Close Ad
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => RewardScreen()), 
                          (route) => false
                        );
                     },
                     child: const Text("Close Ad"),
                   )
                 ],
               ),
             );
          } else {
             // Mobile Ad
             AdState.showInterstitialAd(() {
                if (mounted) {
                   Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => RewardScreen()),
                    (route) => false,
                  );
                }
             });
          }
       } else {
          // No Ad
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => RewardScreen()),
            (route) => false,
          );
       }
  }

  void _endGame({bool isDraw = false}) {
    // If explicit draw, override validation
    if (isDraw) {
       Navigator.pushReplacement(
         context, 
         MaterialPageRoute(builder: (_) => RewardScreen(isDraw: true))
       );
       return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Game?'),
        content: const Text('Are you sure you want to end the game and return to Home?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _session.endGame(); // Notify DB
              _proceedToReward(); // Apply rewards and navigate
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _themePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  void _shuffleQuestions() {
    if (_session.tileOwnership.any((owner) => owner.isNotEmpty)) { // Check if any tile is owned
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot shuffle once the game has started!')),
      );
      return;
    }

    setState(() {
      // Simple shuffle for MVP
      // In a real app, we might want to fetch new questions or just shuffle existing
      final random = Random();
      for (int i = _session.questions.length - 1; i > 0; i--) {
        int n = random.nextInt(i + 1);
        var tempQ = _session.questions[i];
        _session.questions[i] = _session.questions[n];
        _session.questions[n] = tempQ;
        
        var tempO = _session.options[i];
        _session.options[i] = _session.options[n];
        _session.options[n] = tempO;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Questions Shuffled!')),
    );
  }

  Future<void> _saveGame() async {
    final saveData = {
      'session': _session.fullToJson(),
      // 'tileOwnership': _tileOwnership.map((k, v) => MapEntry(k.toString(), v)), // Removed
      // 'currentTurn': _session.currentTurn, // Removed, part of session
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (DevConfig.isDevMode.value) {
      // Dev Mode: Local Storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_game', json.encode(saveData));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game Saved Locally (Dev Mode)!'), backgroundColor: Colors.green),
        );
      }
    } else {
      // Service Mode: Supabase
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must be logged in to save!'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        await Supabase.instance.client.from('saved_games').upsert({
          'user_id': user.id,
          'game_data': saveData,
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game Saved to Cloud!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('Supabase Save Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save to Cloud.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _loadGame() async {
    Map<String, dynamic>? saveData;

    if (DevConfig.isDevMode.value) {
      // Dev Mode: Local Storage
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString('saved_game');
      if (savedString != null) {
        saveData = json.decode(savedString);
      }
    } else {
      // Service Mode: Supabase
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must be logged in to load!'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        final response = await Supabase.instance.client
            .from('saved_games')
            .select()
            .eq('user_id', user.id)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          saveData = response['game_data'];
        }
      } catch (e) {
        print('Supabase Load Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load from Cloud.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    if (saveData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved game found.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      // Confirm Load
      if (mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Load Saved Game?'),
            content: Text('Found a game saved on ${saveData!['timestamp']?.substring(0, 16).replaceAll('T', ' ')}. Load it?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Load'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() {
            _session.loadFromJson(saveData!['session']);
            
            // _tileOwnership.clear(); // Removed
            // (saveData['tileOwnership'] as Map<String, dynamic>).forEach((k, v) { // Removed
            //   _tileOwnership[int.parse(k)] = v; // Removed
            // });
            
            // _session.currentTurn = saveData['currentTurn']; // Removed, part of session
            _isPaused = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game Loaded!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      print('Error parsing game data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to parse game data.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildWinningLinesOverlay() {
    List<Widget> overlays = [];
    final myRole = _session.myRole;
    final opponentRole = myRole == 'A' ? 'B' : 'A';
    
    // Helper to add line
    void addLine(String type, int index, String player) {
       // type: 'row', 'col', 'd1', 'd2'
       final color = player == 'A' ? AppColors.playerA : AppColors.playerB;
       // We use a stronger color for the outline
       final outlineColor = player == 'A' ? AppColors.hostPrimary : AppColors.guestPrimary;
       
       double top = 0;
       double left = 0;
       double width = 0;
       double height = 0;
       double rotation = 0;
       
       // Grid calculation:
       // AspectRatio 1:1. 
       // Padding 16. Grid spacing 8.
       // We can use LayoutBuilder ideally, but inside GridView stack is tricky.
       // Assuming standard container size.
       // Best way is to use `Positioned` with percentage or fractional logic if possible.
       // Check GridView properties:
       // crossAxisCount 5, spacing 8.
       
       // Let's assume the Container size is W.
       // Cell Width = (W - 4*8) / 5.
       // Total Spacing = 32.
       // Let's use LayoutBuilder inside the Overlay logic? 
       // No, we are in a Stack inside AspectRatio. So constraint is 100% width/height.
       
       overlays.add(
         LayoutBuilder(
           builder: (context, constraints) {
             final w = constraints.maxWidth;
             // Calculate cell size
             final cellW = (w - 32) / 5; // 32 = 4 gaps * 8px
             // Actually, GridView padding is 16. So available width inside grid is w-32?
             // No, GridView padding is part of the scroll view.
             // Line 1104: padding: const EdgeInsets.all(16)
             // So the content starts at 16,16.
             // Available plotting area is w.
             
             final gridW = w - 32; // Remove padding
             final cellSize = (gridW - 32) / 5; // Remove 4 gaps
             
             double posX = 16.0;
             double posY = 16.0;
             double lineW = 0;
             double lineH = 0;
             
             if (type == 'row') {
                posX = 16.0;
                posY = 16.0 + (index * (cellSize + 8));
                lineW = gridW; // Full width
                lineH = cellSize;
             } else if (type == 'col') {
                posX = 16.0 + (index * (cellSize + 8));
                posY = 16.0;
                lineW = cellSize;
                lineH = gridW; 
             } else if (type == 'd1') { // TL-BR
                // Diagonal is tricky with pure box. We need rotation or SVG.
                // Simplified: Just use a rotated container centered.
                // Hypotenuse length ~ sqrt(2) * gridW
                // Rotation 45 deg?
                // For MVP, Diagonals are hard to draw as a simple box.
                // Let's use a CustomPainter instead is cleaner.
                return const SizedBox.shrink(); // Use Painter for all instead
             }
             
             // Check Painter approach below
             return const SizedBox.shrink();
           }
         )
       );
    }
    
    // Switch to CustomPainter for clean overlay
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: BingoLinePainter(
            session: _session,
            tileOwnership: _session.tileOwnership,
            primaryA: AppColors.hostPrimary,
            primaryB: AppColors.guestPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHostButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    // Kept for reference or future use, though currently unused in build
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _resolveQuestionText(int index, String? stateQ) {
      if (index < 0 || index >= _session.questions.length) {
         return stateQ ?? 'Loading...';
      }
      
      final baseQ = _session.questions[index];
      final isEnglish = _session.language == 'en';

      // 1. Resolve Base Content (Fallback)
      String effectiveContent = baseQ; // Default Korean
      
      // If English, try to find content_en from parsed map? 
      // _session.questions is List<String>. It only stored the Korean content string originally?
      // Wait, _session.questions is populated in `_loadFromMap` from `game_sessions` table which has `questions` JSONB array.
      // But locally `_session.questions` is `List<String>`.
      // The `options` list stores the FULL map.
      // So we should look at `_session.options[index]['content_en']` if available.
      
      if (index < _session.options.length) {
         final opts = _session.options[index];
         if (isEnglish) {
             final enContent = opts['content_en']; // We added this in GameSession
             if (enContent != null && enContent.toString().isNotEmpty) {
                 effectiveContent = enContent.toString();
             }
         }
         
         final variants = isEnglish ? opts['variants_en'] : opts['variants']; // Choose map based on lang
         
         if (variants != null && variants is Map) {
             // Resolve Variant
             final turn = _session.currentTurn; 
             final isHostTurn = (turn == 'A');
             
             String norm(String? g) {
                 if (g == null || g.isEmpty) return 'm';
                 final low = g.toLowerCase();
                 if (low.startsWith('f') || low == 'female') return 'f';
                 return 'm';
             }
             final hGen = norm(_session.hostGender); 
             final gGen = norm(_session.guestGender); 
             
             // Attacker speaks to Defender
             String attacker = isHostTurn ? hGen : gGen;
             String defender = isHostTurn ? gGen : hGen;
             
             final key = "var_${attacker}_${defender}";
             // Note: English keys we stored as 'var_m_f' (stripped _en) for consistency
             
             if (variants[key] != null && variants[key].toString().isNotEmpty) {
                return variants[key].toString();
             }
         }
      }
      
      // If we are in English mode and we only have Korean stateQ passed in via state...
      // The stateQ usually comes from `game_state` in DB which might be pre-rendered or just content?
      // Actually `interactionState['question']` is usually populated with `_resolveQuestionText` result by the sender?
      // No, sender sends index. Receiver resolves?
      // If sender resolves and puts it in `question` field of json, then receiver sees that string.
      // Ideally, `interactionState` should just have index.
      // But `GameSession` `startInteraction` puts `question: questions[index]` (Korean default).
      
      // If stateQ is provided and we can't resolve dynamic (e.g. index mismatch), use stateQ.
      // But if we want English, and stateQ is Korean, we prefer our local resolution if possible.
      if (index >= 0 && index < _session.options.length) {
          return effectiveContent;
      }

      return stateQ ?? effectiveContent;
  }

  String _getQuestionLabel(String? type) {
    if (type == 'balance' || type == 'B') return 'BALANCE GAME';
    if (type == 'truth' || type == 'T') return 'TRUTH OR DARE';
    if (type == 'mini' || type == 'mini_game_win') return 'Mini'; // Handle Mini Game
    return 'BINGO QUESTION';
  }

  void _launchRandomMiniGame(int index) {
      final random = Random();
      final gameType = random.nextBool() ? 'mini_target' : 'mini_penalty';
      _launchMiniGame(index, gameType);
  }
  
  Future<void> _launchMiniGame(int index, String gameType) async {
      // 1. Notify Backend (this triggers UI update for BOTH players)
      await _session.startInteraction(index, gameType, _session.myRole); 
  }
}

class BingoLinePainter extends CustomPainter {
  final GameSession session;
  final List<String> tileOwnership;
  final Color primaryA;
  final Color primaryB;

  BingoLinePainter({
    required this.session,
    required this.tileOwnership,
    required this.primaryA,
    required this.primaryB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid Setup
    final pad = 16.0;
    final gap = 8.0;
    final gridW = size.width - (pad * 2);
    final cellSize = (gridW - (gap * 4)) / 5;

    final paintA = Paint()
      ..color = primaryA
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 // Thick bold line
      ..strokeCap = StrokeCap.round;

    final paintB = Paint()
      ..color = primaryB
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Helper to get center of cell
    Offset getCenter(int r, int c) {
      double x = pad + c * (cellSize + gap) + cellSize / 2;
      double y = pad + r * (cellSize + gap) + cellSize / 2;
      return Offset(x, y);
    }

    // Check Lines
    void drawLine(List<int> indices, String owner) {
       // Identify line type (row/col/diag)
       // Determine start and end points
       int first = indices.first;
       int last = indices.last;
       
       int r1 = first ~/ 5; int c1 = first % 5;
       int r2 = last ~/ 5; int c2 = last % 5;
       
       Offset start = getCenter(r1, c1);
       Offset end = getCenter(r2, c2);
       
       // Extend the line slightly beyond centers to cover the full cells
       final dir = (end - start);
       final len = dir.distance;
       if (len == 0) return;
       final unit = dir / len;
       final extension = cellSize / 2 * 1.2; // Extend
       
       final p1 = start - (unit * extension);
       final p2 = end + (unit * extension);
       
       canvas.drawLine(p1, p2, owner == 'A' ? paintA : paintB);
    }
    
    // Rows
    for (int r = 0; r < 5; r++) {
       _checkAndDraw(r * 5, 1, 5, drawLine); 
    }
    // Cols
    for (int c = 0; c < 5; c++) {
       _checkAndDraw(c, 5, 5, drawLine);
    }
    // D1
    _checkAndDraw(0, 6, 5, drawLine);
    // D2
    _checkAndDraw(4, 4, 5, drawLine);
  }
  
  void _checkAndDraw(int start, int step, int count, Function(List<int>, String) onDraw) {
    List<int> indices = [];
    String? firstOwner;
    bool consistent = true;
    
    for (int i=0; i<count; i++) {
      int idx = start + (i * step);
      indices.add(idx);
      String owner = tileOwnership[idx];
      
      if (owner.isEmpty || owner == 'LOCKED' || owner == 'X') {
        consistent = false;
        break;
      }
      if (firstOwner == null) firstOwner = owner;
      else if (firstOwner != owner) {
        consistent = false;
        break;
      }
    }
    
    if (consistent && firstOwner != null) {
      onDraw(indices, firstOwner);
    }
  }

  @override
  bool shouldRepaint(covariant BingoLinePainter oldDelegate) {
     return oldDelegate.tileOwnership != tileOwnership;
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final String iconPath;
  final String label;
  final Color color;

  const _HoverableMenuItem({
    required this.iconPath,
    required this.label,
    required this.color,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        height: 40,
        alignment: Alignment.centerRight, // Align to the right
        child: _isHovering
            ? Text(
                widget.label,
                textAlign: TextAlign.right, // Align text to right
                style: TextStyle(
                  fontFamily: 'NURA',
                  fontWeight: FontWeight.w300, // Light
                  fontSize: 16,
                  color: widget.color,
                ),
              )
            : SvgPicture.asset(
                widget.iconPath,
                width: 24,
                height: 24,
                // Removed colorFilter to show original SVG colors
              ),
      ),
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  final String text;
  final Color hoverColor;

  const _HoverMenuItem({required this.text, required this.hoverColor});

  @override
  _HoverMenuItemState createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  // ignore: unused_field
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Text(
        widget.text,
        style: TextStyle(
          color: _isHovered ? widget.hoverColor : Colors.black87,
          fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
