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
import 'package:talkbingo_app/services/sound_service.dart';
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
import 'package:talkbingo_app/widgets/glowing_cursor_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:talkbingo_app/widgets/draggable_floating_button.dart';
import 'package:record/record.dart'; // Audio Recorder
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talkbingo_app/utils/file_helper.dart';
import 'package:audioplayers/audioplayers.dart'; // For Playback
import 'package:talkbingo_app/services/onboarding_service.dart';
import 'package:talkbingo_app/widgets/coach_mark_overlay.dart';
import 'package:talkbingo_app/widgets/game_tooltip.dart';

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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentPage = 1;
  final GameSession _session = GameSession();
  bool _navigating = false; // Add flag to prevent multiple navigations
  
  // Floating Scores State
  final List<Widget> _floatingScores = [];
  int _previousGp = 0;
  
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
  bool get _isHost => _session.myRole == 'A'; // Derive from session role
  bool _isPaused = false;
  final String _latestMessage = "Welcome to TalkBingo! Let's start.";
  final int _badgeCount = 0;
  
  // Bingo Line Animation
  late AnimationController _bingoLineController;
  int _previousLineCount = 0;

  // Animations State
  late ConfettiController _confettiController;
  Set<int> _winningTiles = {};
  // Add direct tracker for button sync
  int _targetPage = 1;

  // State for Entrance Notification
  bool _hasShownEntranceToast = false;

  // State for Challenge / Notification Modal Tracking
  Map<String, dynamic>? _previousInteractionState;
  bool _challengeNotificationShown = false;
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  // Sound Logic
  String _previousText = "";
  
  // Voice Recording & Playback State
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  String? _recordingPath;
  bool _isRecording = false;
  DateTime? _recordStartTime;
  bool _isConvertingSTT = false; // specific flag for STT visual state

  // Two-Tap Preview State
  int? _previewIndex;

  // ── Contextual Tooltip State ──
  String? _activeTooltipMessage;
  bool _hasShownTapConfirmTip = false;
  bool _hasShownLockedCellTip = false;
  bool _hasShownChallengeTip = false;
  bool _hasShownBingoTip = false;
  int _chatHintIndex = 0; // Cycle through dynamic hints

  void _showGameTooltip(String messageKey) {
    if (!mounted) return;
    setState(() {
      _activeTooltipMessage = AppLocalizations.get(messageKey);
    });
  }

  void _dismissGameTooltip() {
    if (!mounted) return;
    setState(() {
      _activeTooltipMessage = null;
    });
  }

  // ── Coach Mark ──
  bool _showCoachMark = false;
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _tickerKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _hasInput = _chatController.text.trim().isNotEmpty;
    _speech = stt.SpeechToText();
    _initSpeech();
    
    // Clear Stale Chat Data
    _unreadCount = 0;
    _latestChatPreview = null;
    _lastProcessedMsg = null;
    
    // Initialize Sound Service
    SoundService().init(); // Fire and forget initialization
    _audioRecorder = AudioRecorder(); // Initialize Recorder
    _audioPlayer = AudioPlayer(); // Initialize Player
    
    _bingoLineController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pageController = PageController(initialPage: 1); 
    
    // Initialize previous points
    _previousGp = _session.gp;
    _previousTileOwnership = List.from(_session.tileOwnership);
    
    // Review Mode: Pause Interaction
    if (widget.isReviewMode) {
      _isPaused = true;
    }
    
    // Listen to Session
    _session.addListener(_onSessionUpdate);
    
    // Listen to broadcast events for cursor sharing
    _cursorEventSubscription = _session.gameEvents.listen((payload) {
      final type = payload['type'];
      if (type == 'cursor' || type == 'cursor_lift') {
        _session.handleCursorEvent(payload);
      } else if (type == 'preview') {
        _session.handlePreviewEvent(payload);
        if (mounted) setState(() {});
      }
    });
    
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
       _initGameCoachMark();
    });

    // Polling Fallback for Game Screen (Robust Sync)
    // Run periodically to ensure eventual consistency
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
       if (mounted && _session.sessionId != null) {
          debugPrint("[Polling] Refreshing Session...");
          _session.refreshSession();
       }
    });

    // Listen to chat controller for robust state
    _chatController.addListener(() {
         final hasInput = _chatController.text.trim().isNotEmpty;
         if (_hasInput != hasInput) {
            setState(() => _hasInput = hasInput);
         }
    });

    WidgetsBinding.instance.addObserver(this); // Add Observer for Keyboard Metrics
  }

  Future<void> _initGameCoachMark() async {
    final shouldShow = await OnboardingService.shouldShowCoachMark('game');
    await OnboardingService.incrementVisit('game');
    if (shouldShow && mounted) {
      setState(() => _showCoachMark = true);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Detect Keyboard Opening (Inset increases)
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0 && _targetPage == 0) {
       // Keyboard active on Chat Tab
       // Wait slightly for resize to happen, then scroll
       Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.hasClients) {
             _chatScrollController.animateTo(
               _chatScrollController.position.maxScrollExtent,
               duration: const Duration(milliseconds: 200),
               curve: Curves.easeOut,
             );
          }
       });
    }
  }

  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _cursorEventSubscription;
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove Keyboard Metrics Observer
    AdState.isGameActive.value = false;
    _pollingTimer?.cancel();
    _bingoLineController.dispose();
    _confettiController.dispose();
    _cursorEventSubscription?.cancel();
    _session.removeListener(_onSessionUpdate);
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _chatScrollController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    SoundService().stopBgm(); // Stop music when leaving screen
    _audioRecorder.dispose();
    _audioPlayer.dispose();
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
    setState(() {}); // Trigger rebuild to reflect session changes (e.g. Language)

    // 0. Guest Join Notification (Toast)
    if (_isHost && !_hasShownEntranceToast && 
        _session.guestNickname != null && _session.guestNickname!.isNotEmpty) {
      _hasShownEntranceToast = true;
      final guestName = _session.guestNickname!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.person_add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.get('guest_joined').replaceAll('{name}', guestName),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // 1. Check for Game Over (Global Sync)
    // FORCE DEBUG:
    debugPrint("[GameScreen] Update: Status=${_session.gameStatus}, Nav=$_navigating"); 

    // 0. BINGO CHECK FIRST — must run before paused_ad handler
    // so that opponent can see the bingo modal even when winner already started ad break
    if (_session.gameStatus == 'playing' || _session.gameStatus == 'waiting' || _session.gameStatus == 'paused_ad') {
       _checkBingoState();
       
       // Trigger Bingo Line Animation
       int currentLineCount = _countAllBingoLines();
       if (currentLineCount > _previousLineCount) {
          _bingoLineController.forward(from: 0.0);
          HapticFeedback.heavyImpact(); // Add tactile feedback
          // Tooltip 5: Bingo cells untouchable (once per session)
          if (!_hasShownBingoTip) {
            _hasShownBingoTip = true;
            _showGameTooltip('tip_bingo_untouchable');
          }
       }
       _previousLineCount = currentLineCount;
    }

    // Auto-trigger challenge hint mid-game (once, around turn 8+)
    if (!_hasShownChallengeTip && _session.turnCount >= 8) {
      // Check if opponent has any owned cells on the board
      final hasOpponentCells = _session.tileOwnership.any(
        (o) => o.isNotEmpty && o != _session.myRole && !o.startsWith('LOCKED')
      );
      if (hasOpponentCells) {
        _hasShownChallengeTip = true;
        _showGameTooltip('tip_challenge_hint');
      }
    }

    // 1. Check for Mid-Game Ad Break (Synced Handshake)
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

    // (Bingo state check already done above, before paused_ad handler)

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
           title: Text("Game Over! 🏁", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
           content: Text("The game has ended.\nProceed to collect your rewards!", style: GoogleFonts.alexandria(fontSize: 14, color: Colors.black87)),
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
    
    // 2. Check for GP Gain (Tile Claim)
    // Detect newly acquired tiles to award points locally and show animation AT THE TILE
    bool tileAnimationShown = false;
    for (int i = 0; i < 25; i++) {
       String owner = _session.tileOwnership[i];
       if (owner == _session.myRole && _previousTileOwnership[i] != _session.myRole) {
          // I gained this specific tile 'i'
          tileAnimationShown = true;
          // Award points
          Future.microtask(() => _session.addPoints(g: 1));
          
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
       // Sync previous GP to prevent double animation from generic check below
    }
    
    // Generic GP Check — just sync the variable to prevent future drift
    if (_session.gp > _previousGp) {
       _previousGp = _session.gp;
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

     // 6. Challenge & Notification Modal Detection
     _detectNotificationEvents();

     if (mounted) setState(() {});
  }

  /// Detect changes in interactionState and tile ownership to show notification modals
  void _detectNotificationEvents() {
    final currentState = _session.interactionState;
    final prevState = _previousInteractionState;

    // --- Modal 1: Challenge Initiated (Defender sees this) ---
    if (currentState != null &&
        currentState['type'] == 'challenge' &&
        currentState['step'] == 'playing' &&
        !_challengeNotificationShown) {
      final String aggressor = currentState['player'] ?? '';
      // Only show to the DEFENDER (the person NOT initiating the challenge)
      if (aggressor.isNotEmpty && aggressor != _session.myRole) {
        _challengeNotificationShown = true;
        final aggressorName = (aggressor == 'A')
            ? (_session.hostNickname ?? 'Host')
            : (_session.guestNickname ?? 'Guest');
        final remaining = _session.challengeCounts[aggressor] ?? 0;
        final title = AppLocalizations.get('challenge_confirm_title');
        final msg = AppLocalizations.get('challenge_initiated')
            .replaceAll('{name}', aggressorName)
            .replaceAll('{remaining}', remaining.toString());
        _showNotificationModal(title: title, message: msg, icon: Icons.sports_mma, iconColor: Colors.redAccent);
      }
    }

    // Reset challenge notification flag when challenge ends
    if (currentState == null || currentState['type'] != 'challenge') {
      _challengeNotificationShown = false;
    }

    // Cycle chat hint during reviewing phase
    if (currentState != null && currentState['step'] == 'reviewing') {
      _chatHintIndex = (_chatHintIndex + 1) % 3;
    }

    // --- Modal 2: Disagree (Reject / Lock) ---
    // Detect tile changing from empty/owned to LOCKED_X where X is MY role
    for (int i = 0; i < 25; i++) {
      final cur = _session.tileOwnership[i];
      final prev = _previousTileOwnership[i];
      // A tile I was trying to claim got locked (rejected)
      if (cur.startsWith('LOCKED_') && cur == 'LOCKED_${_session.myRole}' && prev != cur) {
        // My claim was rejected by opponent
        final opponentRole = _session.myRole == 'A' ? 'B' : 'A';
        final opponentName = (opponentRole == 'A')
            ? (_session.hostNickname ?? 'Host')
            : (_session.guestNickname ?? 'Guest');
        final title = '🔒';
        final msg = AppLocalizations.get('disagree_notify').replaceAll('{name}', opponentName);
        final hint = AppLocalizations.get('disagree_unlock_hint');
        _showNotificationModal(title: title, message: msg, subMessage: hint, icon: Icons.thumb_down_alt, iconColor: Colors.orangeAccent);
        // Tooltip 3: First locked cell hint (once per session)
        if (!_hasShownLockedCellTip) {
          _hasShownLockedCellTip = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _showGameTooltip('tip_locked_cell');
          });
        }
      }
    }

    // --- Modal 3: Cell Won (Opponent acquired a cell via challenge) ---
    // Detect tile changing from MY ownership to OPPONENT ownership
    for (int i = 0; i < 25; i++) {
      final cur = _session.tileOwnership[i];
      final prev = _previousTileOwnership[i];
      if (prev == _session.myRole && cur.isNotEmpty && cur != _session.myRole && !cur.startsWith('LOCKED')) {
        // My tile was stolen by opponent
        final opponentName = (cur == 'A')
            ? (_session.hostNickname ?? 'Host')
            : (_session.guestNickname ?? 'Guest');
        final title = '⚔️';
        final msg = AppLocalizations.get('cell_won').replaceAll('{name}', opponentName);
        _showNotificationModal(title: title, message: msg, icon: Icons.emoji_events, iconColor: Colors.amber);
      }
    }

    // Update tracking state
    _previousInteractionState = currentState != null ? Map<String, dynamic>.from(currentState) : null;
  }

  /// Reusable styled notification modal
  void _showNotificationModal({
    required String title,
    required String message,
    String? subMessage,
    IconData icon = Icons.info_outline,
    Color iconColor = Colors.white,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.alexandria(fontSize: 14, color: Colors.white70)),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(subMessage, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.get('close_btn')),
          ),
        ],
      ),
    );
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
       // Initialize with a bit more aggression for dictation
       _speechEnabled = await _speech.initialize(
         onStatus: (val) {
            debugPrint('[STT] Status: $val');
            if (val == 'done' || val == 'notListening') {
               // Only reset if we didn't manually stop or explicit intent
               if (mounted && _isListening) { 
                 // It stopped by itself (silence). 
                 setState(() => _isListening = false);
               }
            } else if (val == 'listening') {
               if (mounted) setState(() => _isListening = true);
            }
         },
         onError: (val) {
            debugPrint('[STT] Error: $val');
            if (mounted) setState(() => _isListening = false);
         },
       );
       if (mounted) setState(() {});
    } catch (e) {
       debugPrint("Speech Init Error: $e");
    }
  }

  void _startListening() async {
    SoundService().playButtonSound(); // Feedback
    
    // Check Permissions first (Robustness)
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Microphone permission required.")));
            return;
        }
    }

    if (!_speechEnabled) {
       _speechEnabled = await _speech.initialize(); 
       if (!_speechEnabled) return;
    }
    
    // Start Listening with Dictation Mode
    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _session.language == 'ko' ? 'ko-KR' : 'en-US',
      listenMode: stt.ListenMode.dictation, // Smoother for continuous speech
      cancelOnError: false,
      partialResults: true,
      pauseFor: const Duration(seconds: 3), // Wait longer before stopping
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    // Only update if we have confidence or valid words
    if (result.recognizedWords.isNotEmpty) {
        // Debounce or smart append logic could go here, but direct mapping is usually fine for dictation
        setState(() {
          _chatController.text = result.recognizedWords;
          // optional: move cursor to end
          _chatController.selection = TextSelection.fromPosition(TextPosition(offset: _chatController.text.length));
          _hasInput = true;
        });
    }
  }

  // --- Voice Recording Logic ---

  Future<void> _startRecording() async {
    try {
      // Use permission_handler for explicit permission request
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.get('game_mic_permission'))),
            );
          }
          return;
        }
      }

      String? path;
      
      // Only generate path on Mobile/Desktop
      if (!kIsWeb) {
         final dir = await getApplicationDocumentsDirectory();
         final String fileName = 'voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';
         path = '${dir.path}/$fileName';
      }
      
      await _audioRecorder.start(const RecordConfig(), path: path ?? '');
      
      setState(() {
        _isRecording = true;
        _recordStartTime = DateTime.now();
        _recordingPath = path; // Null on Web
      });
      HapticFeedback.mediumImpact(); 
    } catch (e) {
      debugPrint("Start Recording Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.get('game_recording_fail')}$e')),
        );
      }
    }
  }

  Future<void> _stopRecording({bool send = true}) async {
    try {
      // On Web, stop() returns the Blob URL
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null && send) {
         _uploadAndSendVoice(path);
      }
    } catch (e) {
      debugPrint("Stop Recording Error: $e");
    }
  }
  
  Future<void> _uploadAndSendVoice(String localPath) async {
     try {
        // Read bytes using platform-specific helper
        final bytes = await readFileBytes(localPath);
        if (bytes.isEmpty) return;

        // Generate filename
        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final String path = 'voice/${_session.sessionId}/$fileName';
        
        // Upload Binary (Works on Web & Mobile)
        await Supabase.instance.client.storage
            .from('voice-messages')
            .uploadBinary(
                path, 
                bytes,
                fileOptions: const FileOptions(contentType: 'audio/m4a')
            );
            
        // Get Public URL
        final publicUrl = Supabase.instance.client.storage
            .from('voice-messages')
            .getPublicUrl(path);
            
        // Send Message
        _session.sendMessage("🎤 Voice Message", type: 'audio', extra: {'url': publicUrl, 'duration': 0}); 
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voice message sent!")));
     } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send voice message.")));
     }
  }

  // --- New Header Implementation ---
  // --- Redesigned Header (Transparent + Floating Text) ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      // Reduced vertical padding to move content up
      padding: const EdgeInsets.only(top: 0, bottom: 4), 
      child: SafeArea(
        bottom: false,
        child: Column(
          // Align start to avoid centering if container grows
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            // 1. Logo Only
            SvgPicture.asset(
              'assets/images/logo_vector.svg', 
              height: 24, // Slightly smaller logo to save space
            ),
            
            const SizedBox(height: 10), // Reduced spacing from 18 to 10
            
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
                    tooltip: AppLocalizations.get('game_points_tooltip'),
                    child: _buildFloatingText("${AppLocalizations.get('game_points_label')} ${_session.gp}"),
                     itemBuilder: (context) {
                         // Calculate Real-time Stats
                         int filledCells = _session.tileOwnership.where((o) => o == _session.myRole).length;
                         // GP display: cells and lines
                         
                         return [
                            PopupMenuItem(
                              enabled: false, // Info only
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 150),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${AppLocalizations.get('game_bingo_lines')}: ${_session.bingoLines}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text("${AppLocalizations.get('game_bingo_cells')}: $filledCells", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    child: _buildFloatingText(AppLocalizations.get('game_menu')),
                    onSelected: (value) async {
                       SoundService().playButtonSound();
                       if (value == 'Language') {
                          final newLang = _session.language == 'en' ? 'ko' : 'en';
                          _session.setLanguage(newLang);
                          setState(() {}); // Trigger rebuild for Localized Strings & STT Locale
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(newLang == 'ko' ? AppLocalizations.get('game_lang_switched_ko') : AppLocalizations.get('game_lang_switched_en')),
                               duration: const Duration(milliseconds: 1500),
                             )
                          );
                       } else if (value == 'Settings') {
                          _showSettingsDialog();
                       } else if (value == 'Pause') {
                          GameSession().togglePause();
                          setState(() {});
                       } else if (value == 'Save') {
                          // Implement Save Logic
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.get('game_saved'))));
                       } else if (value == 'End') {
                          _endGame(); 
                       }
                    },
                    itemBuilder: (context) {
                         final isPaused = _session.isPaused;
                                                  return [
                             PopupMenuItem(
                               value: 'Language', 
                               child: Container(
                                 width: 120,
                                 alignment: Alignment.centerLeft,
                                 child: Row(children: [
                                   const Icon(Icons.language, size: 18, color: Colors.black54),
                                   const SizedBox(width: 8),
                                   // Show TARGET language to switch TO? Or Current? 
                                   // Convention: Show "Change to X" or Current status.
                                   // Let's show current status with a toggle feel: "KO / EN"
                                   Text(
                                     _session.language == 'en' ? "한국어 🇰🇷" : "English 🇺🇸", 
                                     style: GoogleFonts.alexandria(
                                        color: Colors.black87,
                                        textStyle: const TextStyle(fontFamilyFallback: ['EliceDigitalBaeum'])
                                     )
                                   )
                                 ])
                               ),
                             ),
                             const PopupMenuDivider(),
                             PopupMenuItem(
                               value: 'Settings', 
                               child: Container(
                                 width: 120,
                                 alignment: Alignment.centerLeft,
                                 child: Row(children: [
                                   const Icon(Icons.settings, size: 18, color: Colors.black54),
                                   const SizedBox(width: 8),
                                    Text(AppLocalizations.get('game_settings_label'), style: GoogleFonts.alexandria(color: Colors.black87))
                                 ])
                               ),
                             ),
                            PopupMenuItem(
                              value: 'Pause', 
                              child: Container(
                                width: 120,
                                alignment: Alignment.centerLeft,
                                child: Row(children: [
                                  Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18, color: Colors.black54),
                                  const SizedBox(width: 8),
                                   Text(isPaused ? AppLocalizations.get('game_resume') : AppLocalizations.get('game_pause'), style: GoogleFonts.alexandria(color: Colors.black87))
                                ])
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'Save', 
                              child: Container(
                                width: 120, 
                                alignment: Alignment.centerLeft,
                                child: Row(children: [
                                  const Icon(Icons.save, size: 18, color: Colors.black54),
                                  const SizedBox(width: 8),
                                   Text(AppLocalizations.get('game_save'), style: GoogleFonts.alexandria(color: Colors.black87))
                                ])
                              ),
                            ),
                            PopupMenuItem(
                              value: 'End', 
                              child: Container(
                                width: 120,
                                alignment: Alignment.centerLeft,
                                child: Row(children: [
                                   const Icon(Icons.exit_to_app, size: 18, color: Colors.black54),
                                   const SizedBox(width: 8),
                                    Text(AppLocalizations.get('game_end'), style: GoogleFonts.alexandria(color: Colors.black87))
                                ])
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
    // Show Ad on Game Screen (As requested)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = true;
    });

    // Enforce transparent status bar with dark icons for this screen
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // For light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
      child: PopScope(
        canPop: false, // duplicative of onWillPop: () async => false
        // onPopInvoked: (didPop) {}, // Optional
      child: Scaffold(
        resizeToAvoidBottomInset: !_isQuizInputFocused, // Allow keyboard resizing ONLY when not in Quiz (prevents jumpiness)
        body: BubbleBackground(
          interactive: true,
          child: Stack(
            children: [
              // 1. Main Layout (Header + Content)
              Positioned.fill(
                child: Column(
                  children: [
                    // New Header
                    Container(key: _headerKey, child: _buildHeader()),

                    // Main Content Area
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                             // A. PageView (Chat + Board)
                             PageView(
                               controller: _pageController,
                               children: [
                                   _buildChatView(),
                                   _buildBingoBoard(),
                               ],
                             ),

                             // Invisible anchor for coach mark spotlight on board center
                             Positioned(
                               left: 40, top: 40, right: 40, bottom: 80,
                               child: IgnorePointer(
                                 child: Container(key: _boardKey, color: Colors.transparent),
                               ),
                             ),

                             // B. Quiz Overlay (Inner, below Input)
                             if (_session.interactionState != null && _targetPage == 1)
                               Builder(
                                 builder: (context) {
                                   final state = _session.interactionState!;
                                   final String? type = state['type'];
                                   if (type == 'mini_target' || type == 'mini_penalty') {
                                     return const SizedBox.shrink(); 
                                   }

                                   // Default Quiz Logic
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

                                   if (_targetPage == 0) return const SizedBox.shrink();

                                   String q = state['question'] ?? '';
                                   String optA = state['optionA'] ?? 'A';
                                   String optB = state['optionB'] ?? 'B';
                                   String interactionType = state['type'] ?? 'balance';
                                   // Truth suggestions from DB (not player's submitted answer)
                                   String? truthHints;
                                   if (state['truthOptions'] is List) {
                                     truthHints = (state['truthOptions'] as List).join(', ');
                                   } else if (state['truthOptions'] is String) {
                                     truthHints = state['truthOptions'] as String;
                                   }

                                   // Localize
                                   if (index >= 0) {
                                     final localized = _session.getLocalizedContent(index);
                                     if (localized.isNotEmpty) {
                                       if (localized['q']!.isNotEmpty) q = localized['q']!;
                                       if (localized['A']!.isNotEmpty) optA = localized['A']!;
                                       if (localized['B']!.isNotEmpty) optB = localized['B']!;
                                     }
                                   }

                                   return SizedBox.expand(
                                     child: Container(
                                       color: Colors.black54,
                                       child: QuizOverlay(
                                         question: q,
                                         optionA: optA,
                                         optionB: optB,
                                         type: interactionType,
                                         answer: truthHints,
                                         interactionStep: state['step'] ?? 'answering',
                                         answeringPlayer: state['player'] ?? 'A',
                                         submittedAnswer: state['answer'],
                                         isPaused: _session.gameStatus == 'paused',
                                         onOptionSelected: _handleOptionSelected,
                                         onClose: () => _session.cancelInteraction(),
                                         onInputFocus: (val) {
                                             if (mounted && _isQuizInputFocused != val) {
                                                 setState(() => _isQuizInputFocused = val);
                                             }
                                         },
                                       ),
                                     ),
                                   );
                                 }
                               ),
                      
                             // C. Persistent Input Field (Positioned at Bottom)
                             if (!_isQuizInputFocused) 
                               Positioned(
                                 left: 0, right: 0, bottom: 0,
                                 child: Container(
                                    color: Colors.white,
                                    child: SafeArea(
                                      top: false, 
                                      child: Container(key: _chatKey, child: _buildBottomControls()),
                                    ),
                                 ),
                               ),
                    
                             // D. Rematch & Home Buttons
                             if (widget.isReviewMode && _currentPage == 1)
                               Positioned(
                                 top: 16, right: 16,
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     // Home Button
                                     FloatingActionButton(
                                       heroTag: 'home_btn',
                                       backgroundColor: Colors.white.withValues(alpha: 0.15),
                                       foregroundColor: Colors.white,
                                       mini: true,
                                       onPressed: () {
                                         Navigator.of(context).pushAndRemoveUntil(
                                           MaterialPageRoute(builder: (_) => const HomeScreen()),
                                           (route) => false,
                                         );
                                       },
                                       child: const Icon(Icons.home, size: 22),
                                     ),
                                     const SizedBox(width: 8),
                                     // Rematch Button
                                     FloatingActionButton.extended(
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
                                   ],
                                 ),
                               ),
                          ], 
                        ), // Stack (Inner)
                      ), // Padding
                    ), // Expanded
                  ],
                ), // Column
              ), // Positioned.fill

              // 2. Global Overlays (Outer Stack Level)
              
              // Full-Size Mini Game Overlay
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
                    } else if (type == 'challenge') {
                        // Challenge uses subType to determine mini-game
                        // Uses submitMiniGameScore flow for proper 2-round play
                        final subType = state['subType'] ?? 'mini_target';
                        if (subType == 'mini_target') {
                            return TargetShooterGame(
                              onWin: () async { await _session.closeMiniGame(); },
                              onClose: () { _session.closeMiniGame(); },
                            );
                        } else {
                            return PenaltyKickGame(
                              onWin: () async { await _session.closeMiniGame(); },
                              onClose: () { _session.closeMiniGame(); },
                            );
                        }
                    }
                    return const SizedBox.shrink();
                  }
                ),

              // Floating Scores
              ..._floatingScores,

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2, 
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
              
              // Glowing Cursor Overlay — shared touch position
              if (!widget.isReviewMode)
                GlowingCursorOverlay(
                  opponentX: _session.opponentCursorX,
                  opponentY: _session.opponentCursorY,
                  opponentVisible: _session.opponentCursorVisible,
                  opponentRole: _session.myRole == 'A' ? 'B' : 'A',
                  onPointerMove: (nx, ny) => _session.broadcastCursorPosition(nx, ny),
                  onPointerUp: () => _session.broadcastCursorLifted(),
                ),

              // Draggable Menu Button — hidden during mini-games to avoid covering gameplay
              if (!(_session.interactionState != null && 
                    (_session.interactionState!['type'] == 'mini_target' || 
                     _session.interactionState!['type'] == 'mini_penalty' ||
                     _session.interactionState!['type'] == 'challenge')))
              DraggableFloatingButton(
                isOnChatTab: _targetPage == 0,
                unreadCount: _unreadCount,
                latestMessage: _latestChatPreview,
                themeColor: _themePrimary,
                dragThreshold: 8.0, 
                onTap: () { 
                   SoundService().playButtonSound();
                   final nextPage = _targetPage == 0 ? 1 : 0;
                   setState(() => _targetPage = nextPage);
                   if (_pageController.hasClients) {
                     _pageController.animateToPage(
                       nextPage, 
                       duration: const Duration(milliseconds: 300), 
                       curve: Curves.easeInOut
                     );
                   }
                },
              ),

              // Invisible anchor for coach mark spotlight on floating ticker button
              Positioned(
                right: 16, bottom: 120,
                width: 70, height: 60,
                child: IgnorePointer(
                  child: Container(key: _tickerKey, color: Colors.transparent),
                ),
              ),

              // ── Contextual Game Tooltip Overlay ──
              if (_activeTooltipMessage != null)
                Positioned(
                  left: 24, right: 24, bottom: 140,
                  child: Center(
                    child: GameTooltip(
                      key: ValueKey(_activeTooltipMessage),
                      message: _activeTooltipMessage!,
                      onDismiss: _dismissGameTooltip,
                    ),
                  ),
                ),

              // ── Coach Mark Overlay ──
              if (_showCoachMark)
                CoachMarkOverlay(
                  screenName: 'game',
                  steps: [
                    CoachMarkStep(targetKey: _boardKey, labelKey: 'coach_game_board'),
                    CoachMarkStep(targetKey: _tickerKey, labelKey: 'coach_game_ticker', spotlightPadding: const EdgeInsets.all(12)),
                    CoachMarkStep(targetKey: _chatKey, labelKey: 'coach_game_chat'),
                    CoachMarkStep(targetKey: _headerKey, labelKey: 'coach_game_header'),
                  ],
                  onFinished: () => setState(() => _showCoachMark = false),
                ),
            ],
          ), // Stack (Outer)
      ), // BubbleBackground
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgDark,
            AppColors.bgDark.withOpacity(0.95),
            AppColors.bgDark.withOpacity(0.9),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _chatScrollController,
        // Increased bottom padding to 140 to prevent overlap with input field & ad
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 140),
        itemCount: _session.messages.length,
        itemBuilder: (context, index) {
          final msg = _session.messages[index];
          final sender = msg['sender'] ?? '';
          
          // Determine spacing based on previous sender
          double topSpacing = 16.0;
          if (index > 0) {
            final prevSender = _session.messages[index - 1]['sender'];
            if (prevSender == sender) {
              topSpacing = 4.0;
            }
          }

          // --- 2.2 SYSTEM MESSAGE ---
          if (sender == 'SYSTEM') {
             return Center(
              child: Container(
                margin: EdgeInsets.only(top: topSpacing, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),  // Glassy System Msg
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  msg['text'] ?? '',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- 2.3 QUESTION / ANSWER SYSTEM MESSAGE (Card Style) ---
          if (sender == 'SYSTEM_Q' || sender == 'SYSTEM_A') {
             final player = msg['player'];
             // Pastel Card Colors
             final Color cardColor = (player == 'A') ? AppColors.playerA : AppColors.playerB;
             final Color textColor = AppColors.textDark; // Dark Text for contrast on light pastel
             final Color borderColor = (player == 'A') ? AppColors.hostPrimary.withOpacity(0.3) : AppColors.guestPrimary.withOpacity(0.3);

             return Center(
              child: Container(
                margin: EdgeInsets.only(top: topSpacing, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16), // More card-like
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  msg['text'] ?? '', 
                  style: GoogleFonts.doHyeon(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- 2.1 CHAT MESSAGE (Glassy Vibrant) ---
          final isMe = sender == _session.myRole;
          final time = DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now();
          final timeStr = DateFormat('h:mm a').format(time);
          
          // Nickname Logic
          String senderName = '';
          if (!isMe) {
             senderName = (sender == 'A') 
                ? (_session.hostNickname ?? 'Host') 
                : (_session.guestNickname ?? 'Guest');
          }

          // Chat Bubble Colors (Vibrant Dark)
          final Color bubbleColor;
          if (sender == 'A') {
             bubbleColor = AppColors.hostPrimary.withOpacity(0.85);
          } else {
             bubbleColor = AppColors.guestPrimary.withOpacity(0.85);
          }

          return Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
               // Group Spacing
               SizedBox(height: topSpacing),

               // Opponent Name Label
               if (!isMe && (topSpacing > 4.0)) // Show only if new group
                 Padding(
                   padding: const EdgeInsets.only(left: 16, bottom: 4),
                   child: Text(
                     senderName,
                     style: GoogleFonts.alexandria(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                   ),
                 ),

               // Message Bubble
               Row(
                 mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   // Time Stamp (Left for Me)
                   if (isMe)
                     Padding(
                       padding: const EdgeInsets.only(right: 6, bottom: 2),
                       child: Text(timeStr, style: GoogleFonts.alexandria(fontSize: 9, color: Colors.white38)),
                     ),

                   Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(2),
                          bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBD0558).withOpacity(0.15), // Subtle glow hint
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                        // border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5), // Glass edge
                      ),
                        child: (msg['type'] == 'audio') 
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text("Voice Message", style: GoogleFonts.alexandria(color: Colors.white)),
                                const SizedBox(width: 8),
                                // Simple Play Handler (In real app, manage state per bubble)
                                GestureDetector(
                                    onTap: () async {
                                        final url = msg['extra']?['url'] ?? msg['url']; // backward compat
                                        if (url != null) {
                                           await _audioPlayer.play(UrlSource(url));
                                        }
                                    },
                                    child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                        child: Icon(Icons.volume_up, color: Colors.white, size: 20)
                                    ), 
                                )
                              ],
                            )
                          : Text(
                              msg['text'] ?? '',
                              style: GoogleFonts.doHyeon(
                                fontSize: 14,
                                color: Colors.white, // White text for contrast
                                height: 1.4,
                              ),
                            ),
                   ),

                   // Time Stamp (Right for Opponent)
                   if (!isMe)
                     Padding(
                       padding: const EdgeInsets.only(left: 6, bottom: 2),
                       child: Text(timeStr, style: GoogleFonts.alexandria(fontSize: 9, color: Colors.white38)),
                     ),
                 ],
               ),
            ],
          );
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

  // ── Dynamic Chat Hint based on game state ──
  String _getDynamicChatHint() {
    final state = _session.interactionState;
    if (state != null && state['step'] == 'reviewing') {
      // During empathy review phase, cycle through contextual hints
      final hints = ['tip_chat_hello', 'tip_chat_ask', 'tip_chat_empathy'];
      return AppLocalizations.get(hints[_chatHintIndex % hints.length]);
    }
    return AppLocalizations.get('tip_type_message');
  }

  Widget _buildBottomControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: AdState.showAd,
      builder: (context, showAd, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + (showAd ? 60.0 : 0.0)),
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
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              // onChanged removed in favor of listener in initState for better Web IME support
              decoration: InputDecoration(
                hintText: _isPaused ? 'Game Paused' : _getDynamicChatHint(),
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
            child: GestureDetector(
               onLongPressStart: (_) {
                  if (!_hasInput) _startRecording();
               },
               onLongPressEnd: (_) {
                  if (_isRecording) _stopRecording(send: true);
               },
               onLongPressCancel: () {
                  if (_isRecording) _stopRecording(send: false); // Cancel
               },
               child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: _isRecording ? Colors.red : (_isListening ? Colors.redAccent : (_hasInput ? _themePrimary : Colors.grey[400])),
                     boxShadow: _isRecording || _isListening ? [
                        BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                     ] : [],
                  ),
                  child: Icon(
                     _hasInput 
                         ? Icons.send 
                         : (_isRecording ? Icons.mic : (_isListening ? Icons.graphic_eq : Icons.mic)), 
                      color: Colors.white,
                      size: 20,
                  ),
               ),
               onTap: () {
                  if (_hasInput) {
                      _handleSendMessage();
                  } else {
                      // Toggle STT
                      if (_isListening) {
                         _stopListening();
                      } else {
                         _startListening();
                      }
                  }
               },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendMessage() {
    SoundService().playButtonSound();
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice to text not implemented yet.')),
      );
      return;
    }

    // Stop STT before sending to prevent _onSpeechResult re-populating the input
    if (_isListening) {
      _stopListening();
    }

    _session.sendMessage(text);
    _chatController.clear();
    setState(() {
      _hasInput = false;
    }); 
  }



  // Game State
  // Game State
  // Removed local _tileOwnership to use _session.tileOwnership
  // Removed local _currentTurn to use _session.currentTurn
  // int? _hoveredIndex; // For hover effect - REMOVED
  int? _pressedIndex; // For touch/press effect
  // int? _activeQuizIndex; // For full-size overlay - REMOVED

  bool _hasInput = false;
  bool _isQuizInputFocused = false; // Track if Quiz Input is active (to hide chat bar)

  // Interaction Handlers

  /// Determine the preview label for a cell based on its state
  String _getPreviewLabel(int index) {
    final owner = _session.tileOwnership[index];
    // Opponent's cell → challenge
    if (owner.isNotEmpty && owner != _session.myRole && !owner.startsWith('LOCKED')) {
      return '⚔️';
    }
    // Locked cell → lock
    if (owner.startsWith('LOCKED')) {
      return '🔒';
    }
    // Empty cell → B or T based on question type
    if (index < _session.options.length) {
      final type = _session.options[index]['type'] ?? 'balance';
      return type == 'truth' ? 'T' : 'B';
    }
    return 'B';
  }

  Future<void> _onTileTapped(int index) async {
    SoundService().playButtonSound();
    // Review Mode: Block Interaction
    if (widget.isReviewMode) return;

    if (_isPaused) {
       _showSnackBar("Game paused. Please wait.");
       return;
    }
    final owner = _session.tileOwnership[index];

    // Own tile → no action
    if (owner.isNotEmpty && owner == _session.myRole && !owner.startsWith('LOCKED')) {
      _showSnackBar('This tile is already taken!');
      return;
    }

    // Turn check
    if (_session.currentTurn != _session.myRole) {
       _showSnackBar("It's not your turn!");
       return;
    }

    // ============ TWO-TAP SYSTEM ============
    // FIRST TAP: Set preview + broadcast
    if (_previewIndex != index) {
      setState(() { _previewIndex = index; });
      await _session.broadcastPreview(index, _getPreviewLabel(index));
      // Context-aware first-tap tooltip (once per type per session)
      if (owner.startsWith('LOCKED')) {
        // Locked cell that may be unlockable
        final int lockedAt = _session.lockedTurns[index.toString()] ?? 0;
        final int turnsSinceLock = _session.turnCount - lockedAt;
        if (turnsSinceLock > 2) {
          // Cooldown expired → show "한번 더 누르면 도전!"
          _showGameTooltip('tip_locked_unlock');
        }
      } else if (owner.isNotEmpty && owner != _session.myRole) {
        // Opponent's cell → show remaining challenges "N/2 기회!"
        final int remaining = _session.challengeCounts[_session.myRole] ?? 0;
        setState(() {
          _activeTooltipMessage = AppLocalizations.get('tip_challenge_remaining')
              .replaceAll('{remaining}', remaining.toString());
        });
      } else if (!_hasShownTapConfirmTip) {
        // Normal empty cell → "한번 더 누르면 선택확정!"
        _hasShownTapConfirmTip = true;
        _showGameTooltip('tip_tap_confirm');
      }
      return;
    }

    // SECOND TAP (same cell): Execute action
    // Clear preview first
    setState(() { _previewIndex = null; });
    await _session.clearPreview();

    // --- Handle by cell type ---

    // 1. Opponent's cell → Challenge
    if (owner.isNotEmpty && owner != _session.myRole && !owner.startsWith('LOCKED')) {
       if (_session.isTileInCompletedLine(index)) {
          _showSnackBar("Cannot challenge a completed Bingo line!");
          HapticFeedback.heavyImpact();
          return;
       }
       final int remaining = _session.challengeCounts[_session.myRole] ?? 0;
       if (remaining <= 0) {
          _showSnackBar("No Challenge attempts remaining!");
          return;
       }
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           backgroundColor: const Color(0xFF2D2D3A),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           title: Row(
             children: [
               const Icon(Icons.sports_mma, color: Colors.redAccent, size: 28),
               const SizedBox(width: 10),
               Expanded(child: Text(AppLocalizations.get('challenge_confirm_title'), style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
             ],
           ),
           content: Text(
             AppLocalizations.get('challenge_confirm_desc').replaceAll('{remaining}', remaining.toString()),
             style: GoogleFonts.alexandria(fontSize: 14, color: Colors.white70),
           ),
           actions: [
             TextButton(child: Text(AppLocalizations.get('cancel'), style: GoogleFonts.alexandria(color: Colors.white38)), onPressed: () => Navigator.pop(ctx)),
             ElevatedButton(
               child: Text(AppLocalizations.get('challenge_btn')),
               onPressed: () {
                 Navigator.pop(ctx);
                 _session.startChallenge(index);
               },
               style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
             )
           ],
         )
       );
       return;
    }

    // 2. Locked cell → Mini Game (with cooldown check)
    if (owner.startsWith('LOCKED')) {
       final int lockedAt = _session.lockedTurns[index.toString()] ?? 0;
       final int turnsSinceLock = _session.turnCount - lockedAt;
       if (turnsSinceLock <= 2) {
           _showSnackBar("🔒 Locked! Cooldown active for ${3 - turnsSinceLock} turns.");
           HapticFeedback.heavyImpact();
           return;
       }
       _session.startInteraction(index, 'mini', _session.myRole);
       return;
    }

    // 3. Check if already interacting
    if (_session.interactionState != null) {
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

    // 4. Empty cell → Start Interaction (Quiz)
  // Use getLocalizedContent() for proper EN/KO content in game log
  final localized = _session.getLocalizedContent(index);
  String qText = localized['q'] ?? '';
  String type = 'balance';
  String optA = localized['A'] ?? '';
  String optB = localized['B'] ?? '';
  List<String>? suggestions;
  
  if (index < _session.options.length) {
     final opts = _session.options[index];
     type = opts['type'] ?? 'balance';
     
     // Answer hints — use localized version
     final answerStr = localized['answer'] ?? '';
     if (answerStr.isNotEmpty) {
       suggestions = answerStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
     }

  await _session.startInteraction(
    index, 
    type, 
    _session.myRole,
    q: qText,
    A: optA,
    B: optB,
    suggestions: suggestions
  );
  }
  } // end _onTileTapped

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
    // Bottom controls overlay ~120px at the bottom of the PageView.
    // Add bottom padding so Center positions the board in the visible area above controls.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 120.0),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {

              final boardSize = constraints.maxWidth;
              return GestureDetector(
                onPanUpdate: (details) {
                  /* TEMPORARY DISABLE - BUILD FIX
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPos = box.globalToLocal(details.globalPosition);
                  double x = localPos.dx - 16;
                  double y = localPos.dy - 16;
                  double contentSize = boardSize - 32;
                  double tileSize = contentSize / 5;
                  
                  if (x < 0 || y < 0 || x > contentSize || y > contentSize) {
                     if (_hoveredIndex != null) {
                        setState(() => _hoveredIndex = null);
                        _session.broadcastHover(null);
                     }
                     return;
                  }
                  
                  int col = (x / tileSize).floor().clamp(0, 4);
                  int row = (y / tileSize).floor().clamp(0, 4);
                  int index = row * 5 + col;
                  
                  if (_hoveredIndex != index) {
                    setState(() => _hoveredIndex = index);
                    _session.broadcastHover(index);
                  }
                  */
                },
                onPanEnd: (details) {
                   /*
                   setState(() => _hoveredIndex = null);
                   _session.broadcastHover(null);
                   */
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
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
                            return _buildBingoTile(index)
                                .animate(delay: (50 * index).ms) // Staggered Entrance
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
                          },
                        ),
                        


                        
                        // Layer 2: Remote Hover Overlay (Disabled)
                        ValueListenableBuilder<int?>(
                           valueListenable: _session.remoteHoverIndex,
                           builder: (context, remoteIndex, child) {
                              return const SizedBox.shrink(); // DISABLED
                           }
                        ),
                        
                        // Layer 3: Winning Lines
                        _buildWinningLinesOverlay(),
                      ],
                    ),
                ),
              );
            }
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
            value: _session.gp,
            duration: const Duration(milliseconds: 1000), // Slow satisfying roll
            textStyle: GoogleFonts.alexandria(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text("GP", style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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

  Widget _buildTurnIndicator() {
    final currentTurn = _session.currentTurn;
    final myRole = _session.myRole;
    final isMyTurn = (currentTurn == myRole);
    final isA = (currentTurn == 'A');
    
    final String label = isMyTurn 
        ? "MY TURN"
        : (isA 
            ? "MP ${_session.hostNickname ?? 'Host'}" 
            : "CP ${_session.guestNickname ?? 'Guest'}");
    
    final Color turnColor = isA ? AppColors.hostPrimary : AppColors.guestPrimary;
    
    // Style Logic:
    // If Not My Turn (Waiting) -> Transparent Background/Outline, Colored Text (Subtle)
    // If My Turn -> Colored Background, White Text (Prominent)
    
    final Color bgColor = isMyTurn ? turnColor : Colors.transparent;
    final Color borderColor = isMyTurn ? Colors.white.withOpacity(0.5) : Colors.transparent;
    final Color contentColor = isMyTurn ? Colors.white : turnColor.withOpacity(0.8);
    final List<BoxShadow> shadows = isMyTurn ? [
       BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      )
    ] : [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_fill, 
            color: contentColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: contentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBingoTile(int index) {
  String owner = _session.tileOwnership[index];
  
  // Determine preview label for this cell
  String? cellPreviewLabel;
  if (_previewIndex == index) {
    cellPreviewLabel = _getPreviewLabel(index);
  } else if (_session.remotePreviewCellIndex.value == index) {
    cellPreviewLabel = _session.remotePreviewLabel;
  }
  
  return MouseRegion(
    cursor: (owner == 'X') ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    child: LiquidBingoTile(
      text: "",
      owner: owner,
      isHost: _isHost, 
      isHovered: false,
      isWinningTile: _winningTiles.contains(index),
      previewLabel: cellPreviewLabel,
      onTap: () {
      _onTileTapped(index);
    },
    ),
  );
}

  bool _isGameEndedDialogShown = false;
  // Duplicate _isBingoDialogVisible removed


  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final soundService = SoundService();
            return AlertDialog(
              title: Text(AppLocalizations.get('game_settings_title'), style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BGM Control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.get('game_bgm'), style: GoogleFonts.alexandria(fontSize: 14)),
                      Switch(
                        value: soundService.isBgmEnabled,
                        onChanged: (val) {
                          soundService.setBgmEnabled(val).then((_) => setDialogState(() {}));
                        },
                      ),
                    ],
                  ),
                  if (soundService.isBgmEnabled)
                    Slider(
                      value: soundService.bgmVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        soundService.setBgmVolume(val).then((_) => setDialogState(() {}));
                      },
                    ),
                    
                  const SizedBox(height: 16),
                  
                  // SFX Control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.get('game_sfx'), style: GoogleFonts.alexandria(fontSize: 14)),
                      Switch(
                        value: soundService.isSfxEnabled,
                        onChanged: (val) {
                          soundService.setSfxEnabled(val).then((_) => setDialogState(() {}));
                        },
                      ),
                    ],
                  ),
                  if (soundService.isSfxEnabled)
                    Slider(
                      value: soundService.sfxVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        soundService.setSfxVolume(val).then((_) => setDialogState(() {}));
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.get('close')),
                )
              ],
            );
          }
        );
      }
    );
  }

  // Modified to handle "Wait Handshake" Overlay

  void _showBingoDialog({required int lines, required bool isWinner}) {
    if (_isBingoDialogVisible) return; // Prevent double show
    _isBingoDialogVisible = true;

    final isGameOver = lines >= 3;
    final winnerName = isWinner 
        ? (_isHost ? (_session.hostNickname ?? 'Host') : (_session.guestNickname ?? 'Guest'))
        : (_isHost ? (_session.guestNickname ?? 'Guest') : (_session.hostNickname ?? 'Host'));

    // Helper to build content
    Widget buildContent() {
       // Build main message
       String mainMsg;
       if (isWinner) {
         mainMsg = isGameOver 
             ? AppLocalizations.get('bingo_winner_final')
             : "$lines${AppLocalizations.get('bingo_winner')}";
       } else {
         mainMsg = isGameOver
             ? "${AppLocalizations.get('bingo_loser_final')}$winnerName${AppLocalizations.get('bingo_loser_final_suffix')}"
             : "${AppLocalizations.get('bingo_loser')}$winnerName${AppLocalizations.get('bingo_loser_suffix')}";
       }

       // Ad hint
       final adHint = isGameOver
           ? AppLocalizations.get('bingo_ad_hint_final')
            : "${AppLocalizations.get('bingo_ad_hint_prefix')}${lines + 1} ${AppLocalizations.get('bingo_ad_hint_round')}";

       return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(isWinner ? Icons.celebration : Icons.sentiment_dissatisfied, 
                  color: isWinner ? const Color(0xFFE91E63) : Colors.grey, size: 40),
             const SizedBox(height: 10),
             
             // Title
             Text(
               isWinner 
                 ? (isGameOver ? AppLocalizations.get('bingo_title_final') : AppLocalizations.get('bingo_title'))
                 : AppLocalizations.get('bingo_opponent'),
               style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
             ),
             const SizedBox(height: 10),
             
             // Main message
             Text(
               mainMsg,
               textAlign: TextAlign.center,
               style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
             ),
             
             // Ad hint text at bottom
             if (!_session.adFree) ...[
               const SizedBox(height: 16),
               Text(
                 adHint,
                 textAlign: TextAlign.center,
                 style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
               ),
             ],
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
                  _isBingoDialogVisible = false;
                  Navigator.pop(context);
                  
                  if (_session.adFree) {
                      _session.setGameStatus('playing');
                  } else {
                      await _session.startAdBreak();
                  }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.get('bingo_continue')),
            ),
          
          ElevatedButton(
            onPressed: () {
                _isBingoDialogVisible = false;
                Navigator.pop(context);
                _navigating = true;
                _session.endGame(); 
                _proceedToReward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.get('bingo_end'), style: const TextStyle(color: Colors.white)),
          )
        ] : [
          ElevatedButton(
            onPressed: () {
                _isBingoDialogVisible = false;
                Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.get('bingo_confirm')),
          )
        ],
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
                                _handleAdComplete(); // Reset _navigating + sync ad status
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
      if (_isGameEndedDialogShown) return;
      _isGameEndedDialogShown = true;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_off, color: Colors.grey, size: 40),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.get('board_full_title') ?? '게임 종료',
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.get('board_full_desc') ?? '더 이상 선택할 빙고셀이 없습니다.\n게임을 종료합니다.',
                textAlign: TextAlign.center,
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigating = true;
                _session.endGame();
                _proceedToReward();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                AppLocalizations.get('board_full_end') ?? '결과 보기',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
  }

  void _restartGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Restart Game?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        content: Text('This will clear the board and reset turns.\nCurrent progress will be lost.', style: GoogleFonts.alexandria(fontSize: 14, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.alexandria(color: Colors.black54))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('End Game?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        content: Text('Are you sure you want to end the game?', style: GoogleFonts.alexandria(fontSize: 14, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.alexandria(color: Colors.black54)),
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
            title: Text('Load Saved Game?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            content: Text('Found a game saved on ${saveData!['timestamp']?.substring(0, 16).replaceAll('T', ' ')}. Load it?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.alexandria(color: Colors.black54))),
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
    // Switch to CustomPainter for clean overlay
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _bingoLineController,
          builder: (_, __) {
            return CustomPaint(
              painter: BingoLinePainter(
                session: _session,
                tileOwnership: _session.tileOwnership,
                primaryA: AppColors.hostPrimary,
                primaryB: AppColors.guestPrimary,
                animationValue: _bingoLineController.value,
              ),
            );
          },
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

  // Helper to count TOTAL bingo lines for animation trigger
  int _countAllBingoLines() {
     int lines = 0;
     // Rows
     for(int r=0; r<5; r++) {
        if(_checkLine(List.generate(5, (c)=> r*5+c))) lines++;
     }
     // Cols
     for(int c=0; c<5; c++) {
        if(_checkLine(List.generate(5, (r)=> r*5+c))) lines++;
     }
     // Diagonals
     if(_checkLine([0,6,12,18,24])) lines++;
     if(_checkLine([4,8,12,16,20])) lines++;
     return lines;
  }

  bool _checkLine(List<int> indices) {
     String? first;
     for(int idx in indices) {
        String owner = _session.tileOwnership[idx];
        if(owner.isEmpty || owner == 'X' || owner == 'LOCKED') return false;
        if(first == null) first = owner;
        else if(first != owner) return false;
     }
     return true;
  }
}

class BingoLinePainter extends CustomPainter {
  final GameSession session;
  final List<String> tileOwnership;
  final Color primaryA;
  final Color primaryB;
  final double animationValue; // 0.0 to 1.0

  BingoLinePainter({
    required this.session,
    required this.tileOwnership,
    required this.primaryA,
    required this.primaryB,
    this.animationValue = 1.0,
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
       
       // ANIMATION: Interpolate end point based on value
       final animatedP2 = Offset.lerp(p1, p2, animationValue)!;

       // Draw Main Line
       canvas.drawLine(p1, animatedP2, owner == 'A' ? paintA : paintB);
       
       // Draw Glow (Only if fully drawn or > 0.5)
       if (animationValue > 0.1) {
          final glowPaint = Paint()
            ..color = (owner == 'A' ? primaryA : primaryB).withOpacity(0.5 * animationValue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            
          canvas.drawLine(p1, animatedP2, glowPaint);
       }
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
