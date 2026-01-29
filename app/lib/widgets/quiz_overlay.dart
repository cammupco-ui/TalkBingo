import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import '../models/game_session.dart';

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
  });

  final String interactionStep; // 'answering' or 'reviewing'
  final String answeringPlayer; // 'A' or 'B'
  final String? submittedAnswer;
  final bool isPaused;

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> {
  final bool _showAnswer = false;
  // bool _isSubmitted = false; // Removed in favor of interactionStep
  String? _selectedChoice; // Local tracking for Input field
  
  // For Balance Game
  String? _balanceReason; 

  @override
  void initState() {
    super.initState();
    if (widget.submittedAnswer != null) {
      _selectedChoice = widget.submittedAnswer;
    }
  } 

  @override
  Widget build(BuildContext context) {
    // Determine if it's a Truth Game
    final bool isTruthGame = !_isBalanceGame;
    
    final String title = isTruthGame ? 'TRUTH' : 'BALANCE';

    return Container(
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
                child: _buildContent(),
              ),
            ),
          ),

          // Icons Removed as requested

          // Paused Overlay
          if (widget.isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.95),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded, size: 80, color: AppColors.hostPrimary),
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
              ),
            ),
          
          // Report Button (Bottom-Left)
          Positioned(
            left: 16,
            bottom: 110, // Moved up to avoid Banner Ad (94px + margin)
            child: IconButton(
              icon: const Icon(Icons.flag_rounded, color: Colors.grey, size: 20),
              tooltip: 'Report Content',
              onPressed: _showReportDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("질문 신고하기"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_format),
              title: const Text("맞춤법 오류 (Typo)"),
              onTap: () => _submitReport("Typo"),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("내용 이상함 (Weird)"),
              onTap: () => _submitReport("Weird Content"),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text("기타 (Other)"),
              onTap: () => _submitReport("Other"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _submitReport(String reason) {
    Navigator.pop(context); // Close Dialog
    
    // Resolve Question ID if possible (from Session or Widget)
    // Widget doesn't have ID directly, but Session does.
    // Or we can assume active interaction index.
    final session = GameSession();
    final String qId = session.interactionState?['question'] ?? 'Unknown';
    
    session.reportContent(qId, reason);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("신고가 접수되었습니다. (Report Sent)")),
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
              "상대방이 선택 중입니다...",
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
            "공감 할수 있게 대화 해 보세요",
            style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.hostPrimary),
            textAlign: TextAlign.center,
          ),

        if (mode == 'reviewing')
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AnimatedOutlinedButton(
                      onPressed: () => widget.onOptionSelected('REJECT'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('비공감', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Approve Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AnimatedButton(
                      onPressed: () => widget.onOptionSelected(widget.submittedAnswer ?? 'APPROVED'), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hostPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('공감', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                color: const Color(0xFF7DD3FC), // Sky Blue
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
                color: const Color(0xFFFBCFE8), // Pink
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
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

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
          maxLength: 20, 
          enabled: true, // Keep enabled for vivid text color
          readOnly: readOnly, // Prevent editing if readOnly
          style: const TextStyle(
            fontSize: 16, // Increased size for better visibility
            fontWeight: FontWeight.bold, // Bold for emphasis
            color: Colors.black, // Vivid Black
          ),
          textAlign: TextAlign.center, // Center text for truth answer presentation
          decoration: InputDecoration(
            isDense: true, 
            hintText: readOnly ? '상대방이 답변 중입니다...' : '답변을 입력하거나 선택하세요', 
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: highlightAnswer != null ? const BorderSide(color: AppColors.hostPrimary, width: 2) : BorderSide.none, // Highlight border
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
              child: const Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
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
    // Fix: Remove Opacity widget here. Controlled by parent or disabledStyle.
    // If disabled but selected, we want it full vivid color, not greyed out.
    // If disabled and NOT selected, it will be dimmed by parent Opacity (0.6 * 0.3 = 0.18 roughly).
    
    // We need to apply the opacity for "disabled but no selection yet" case?
    // Parent _buildBalanceContent logic:
    // aOpacity = (highlightAnswer != null && !isASelected) ? 0.3 : 1.0;
    // So if no selection, 1.0.
    // If we are readOnly and no selection (Partner Thinking), we want Dimmed?
    // Old code: 0.6.
    
    // Let's implement the 0.6 opacity via color alpha interaction if needed, or re-add Opacity simplified.
    // But crucial fix is `disabledBackgroundColor` matching active color.

    final double contentOpacity = (enabled || isSelected) ? 1.0 : 0.6;

    return Opacity(
      opacity: contentOpacity,
      child: AnimatedButton(
        onPressed: enabled ? () => widget.onOptionSelected(value) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: Colors.black87,
          // FIX: Override disabled colors to prevent greying out when selected
          disabledBackgroundColor: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1), 
          disabledForegroundColor: Colors.black87,
          
          elevation: isSelected ? 4 : 0, 
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: isSelected ? AppColors.hostPrimary : color, 
                width: isSelected ? 4 : 2 
            ), 
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            height: 1.3, 
          ),
          textAlign: TextAlign.center,
          softWrap: true, 
        ),
      ),
    );
  }
}
