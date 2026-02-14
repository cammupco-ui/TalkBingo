import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import '../models/game_session.dart';
import '../utils/localization.dart';

class QuizOverlay extends StatefulWidget {
  final String question;
  final String optionA;
  final String optionB;
  final String? type;
  final String? answer;
  final Function(String) onOptionSelected;
  final VoidCallback onClose;

  const QuizOverlay({
    super.key,
    required this.question,
    required this.optionA,
    required this.optionB,
    this.type,
    this.answer,
    required this.onOptionSelected,
    required this.onClose,
    this.interactionStep = 'answering',
    this.answeringPlayer = 'A',
    this.submittedAnswer,
    this.isPaused = false,
    this.onInputFocus, // New optional callback
  });

  final String interactionStep; 
  final String answeringPlayer; 
  final String? submittedAnswer;
  final bool isPaused;
  final ValueChanged<bool>? onInputFocus; // Callback definition

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> {
  final bool _showAnswer = false;
  // bool _isSubmitted = false; // Removed in favor of interactionStep
  String? _selectedChoice; // Local tracking for Input field
  
  // For Balance Game
  String? _balanceReason; 
  
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.submittedAnswer != null) {
      _selectedChoice = widget.submittedAnswer;
    }
    
    // Listen to Focus Changes
    _focusNode.addListener(() {
      if (widget.onInputFocus != null) {
        widget.onInputFocus!(_focusNode.hasFocus);
      }
    });
  } 

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  } 

  @override
  Widget build(BuildContext context) {
    // Determine if it's a Truth Game
    final bool isTruthGame = !_isBalanceGame;
    
    final String title = isTruthGame ? 'TRUTH' : 'BALANCE';

    // Get keyboard height manually since Scaffold resize is disabled for Quiz
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight), // Push content up by keyboard height
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98), // Nearly Opaque for readability
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0), // Reduced from 24
            child: Center(
              child: SingleChildScrollView(
                child: _buildContent()
                    .animate()
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
              ),
            ),
          ),

          // Paused Overlay
          if (widget.isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.95),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded, size: 80, color: AppColors.hostPrimary)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 24),
                    Text(
                      "Thinking Time...",
                      style: GoogleFonts.alexandria(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Game is paused.",
                      style: GoogleFonts.alexandria(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                     AnimatedButton(
                      onPressed: () => GameSession().togglePause(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hostPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text("RESUME GAME", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          
          // Report Button (Top-Right)
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.flag_rounded, color: Colors.grey, size: 24),
                tooltip: 'Report Content',
                onPressed: _showReportDialog,
              ),
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 300.ms)
     .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.get('report_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_format),
              title: Text(AppLocalizations.get('report_typo')),
              onTap: () {
                Navigator.pop(dialogContext);
                _submitReport("Typo");
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.get('report_weird')),
              onTap: () {
                Navigator.pop(dialogContext);
                _submitReport("Weird Content");
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(AppLocalizations.get('report_other')),
              onTap: () {
                Navigator.pop(dialogContext);
                _submitReport("Other");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _submitReport(String reason) {
    // Dialog is already closed by the time this is called
    
    // Resolve Question ID if possible (from Session or Widget)
    // Widget doesn't have ID directly, but Session does.
    // Or we can assume active interaction index.
    final session = GameSession();
    final String qId = session.interactionState?['question'] ?? 'Unknown';
    
    session.reportContent(qId, reason);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${AppLocalizations.get('report_sent')} (Report Sent)")),
    );
  }

  Widget _buildContent() {
    // Case 0: Mini Game
    if (widget.type == 'mini') {
      return _buildMiniGameView();
    }

    final bool amIAnswering = GameSession().myRole == widget.answeringPlayer;
    final bool isReviewing = widget.interactionStep == 'reviewing';
    
    String mode;
    if (isReviewing) {
       if (amIAnswering) {
         mode = 'waiting_approval';
       } else {
         mode = 'reviewing';
       }
    } else {
      // Answering Phase
      if (amIAnswering) {
        mode = 'answering';
      } else {
        mode = 'partner_answering';
      }
    }

    return _buildAnsweringView(mode: mode);
  }

  Widget _buildMiniGameView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.gamepad, size: 48, color: AppColors.hostPrimary),
        const SizedBox(height: 16),
        Text(
          "Mini Game in Progress...",
          style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const CircularProgressIndicator(),
      ],
    );
  }

  // Centralized Logic for Game Type
  bool get _isBalanceGame {
    final String safeType = (widget.type ?? '').toLowerCase();
    return safeType == 'balance' || (safeType.isEmpty && widget.optionA.isNotEmpty);
  }

  // Old views removed: _buildWaitingForApprovalView, _buildApprovalView, _buildPartnerAnsweringView

  Widget _buildAnsweringView({required String mode}) {
    final bool isTruthGame = !_isBalanceGame;
    final String title = isTruthGame ? 'TRUTH' : 'BALANCE';
    
    // Determine Read Only Status
    final bool readOnly = mode != 'answering';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.alexandria(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.hostPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Optional: Show "Partner's Turn" banner
        if (mode == 'partner_answering')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.get('quiz_opponent_choosing'),
              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold),
            ),
          ),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            widget.question,
            style: GoogleFonts.doHyeon(
              fontSize: 24, // Increased from 16 for better readability
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Content (Inputs)
        if (isTruthGame)
          _buildTruthContent(readOnly: readOnly, highlightAnswer: widget.submittedAnswer)
        else
          _buildBalanceContent(readOnly: readOnly, highlightAnswer: widget.submittedAnswer),

        const SizedBox(height: 32),

        // Bottom Actions based on Mode
        if (mode == 'waiting_approval')
          Text(
            AppLocalizations.get('quiz_talk_empathy'),
            style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.hostPrimary),
            textAlign: TextAlign.center,
          ),

        if (mode == 'reviewing')
            Row(
              children: [
                // Reject Button (Outline - Grey)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AnimatedOutlinedButton(
                      onPressed: () => widget.onOptionSelected('REJECT'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.grey,
                        backgroundColor: Colors.transparent, // No fill
                      ),
                      child: Text(AppLocalizations.get('quiz_disagree'), style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Approve Button (Outline - Pink, NOT filled)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AnimatedOutlinedButton(
                      onPressed: () => widget.onOptionSelected(widget.submittedAnswer ?? 'APPROVED'), 
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.hostPrimary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: AppColors.hostPrimary,
                        backgroundColor: Colors.transparent, // No fill - appears unselected
                      ),
                      child: Text(AppLocalizations.get('quiz_agree'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.hostPrimary)),
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildBalanceContent({required bool readOnly, String? highlightAnswer}) {
    // Determine selection state
    final bool isASelected = highlightAnswer == 'A' || highlightAnswer == widget.optionA;
    final bool isBSelected = highlightAnswer == 'B' || highlightAnswer == widget.optionB;
    
    // If highlighting, dim the unselected one
    final double aOpacity = (highlightAnswer != null && !isASelected) ? 0.3 : 1.0;
    final double bOpacity = (highlightAnswer != null && !isBSelected) ? 0.3 : 1.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Opacity(
              opacity: aOpacity,
              child: _buildOptionButton(
                context,
                label: widget.optionA,
                color: AppColors.hostPrimary, // Design System: Host Pink
                value: 'A',
                enabled: !readOnly,
                isSelected: isASelected,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Opacity(
              opacity: bOpacity,
              child: _buildOptionButton(
                context,
                label: widget.optionB,
                color: AppColors.guestPrimary, // Design System: Guest Purple
                value: 'B',
                enabled: !readOnly,
                isSelected: isBSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _answerController = TextEditingController();

  @override
  // void dispose() handled above in simplified block
  // void dispose() {
  //   _answerController.dispose();
  //   super.dispose();
  // }

  Widget _buildTruthContent({required bool readOnly, String? highlightAnswer}) {
    // If reviewing/waiting, show the submitted answer instead of input if possible, 
    // or just populate the controller with the answer.
    
    // Check if we need to update controller for display
    if (readOnly && highlightAnswer != null && _answerController.text != highlightAnswer) {
        _answerController.text = highlightAnswer;
    }

    final List<String> suggestions = widget.answer?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

    return Column(
      children: [
        // Input Field
        TextField(
          controller: _answerController,
          focusNode: _focusNode, // Attach FocusNode
          maxLength: 20, 
          enabled: true, 
          readOnly: readOnly, 
          // scrollPadding: const EdgeInsets.only(bottom: 120), // Removed: Handled by resizeToAvoidBottomInset: false logic
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            color: Colors.black, 
          ),
          textAlign: TextAlign.center, 
          decoration: InputDecoration(
            isDense: true, 
            hintText: readOnly ? AppLocalizations.get('quiz_opponent_answering') : AppLocalizations.get('quiz_enter_answer'), 
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: highlightAnswer != null ? const BorderSide(color: AppColors.hostPrimary, width: 2) : BorderSide.none, 
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), 
            counterText: "",
          ),
        ),
        const SizedBox(height: 20),

        // Suggestions Chips (Only show if answering)
        if (suggestions.isNotEmpty && !readOnly) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: suggestions.take(4).map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ConstrainedBox(
                       constraints: const BoxConstraints(maxWidth: 160),
                       child: InkWell(
                         onTap: () {
                           _answerController.text = suggestion;
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             border: Border.all(color: Colors.grey[300]!),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Text(
                             suggestion,
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12), 
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                       ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (!readOnly)
          SizedBox(
            width: double.infinity,
            height: 32, 
            child: AnimatedButton(
              onPressed: () {
                 if (_answerController.text.isEmpty) return;
                 widget.onOptionSelected(_answerController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hostPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(AppLocalizations.get('quiz_submit'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required String value,
    bool enabled = true,
    bool isSelected = false,
  }) {
    final double contentOpacity = (enabled || isSelected) ? 1.0 : 0.6;

    // When selected: solid color fill. When not: light tint.
    final Color bgColor = isSelected ? color : color.withOpacity(0.15);
    final Color textColor = isSelected ? Colors.white : Colors.black87;
    final Color borderColor = isSelected ? color : color.withOpacity(0.4);

    return Opacity(
      opacity: contentOpacity,
      child: AnimatedButton(
        onPressed: enabled ? () => widget.onOptionSelected(value) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          disabledBackgroundColor: bgColor,
          disabledForegroundColor: textColor,
          elevation: isSelected ? 4 : 0, 
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: borderColor, 
                width: isSelected ? 3 : 2,
            ), 
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: textColor,
          ),
          textAlign: TextAlign.center,
          softWrap: true, 
        ),
      ),
    );
  }
}
