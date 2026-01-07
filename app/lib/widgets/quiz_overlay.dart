import 'package:flutter/material.dart';
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
        color: Colors.white.withOpacity(0.98),
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

          // Close Button (Top Right)
          // Hide close button during active interaction unless necessary
          if (widget.interactionStep == 'answering' && GameSession().myRole == widget.answeringPlayer)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, color: Colors.grey, size: 30),
              ),
            ),
          // Pause Button (Top Left - Opposite Close)
          if (widget.interactionStep == 'answering')
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => GameSession().togglePause(),
                icon: Icon(
                  widget.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, 
                  color: Colors.grey, 
                  size: 30
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
                     ElevatedButton.icon(
                      onPressed: () => GameSession().togglePause(),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text("RESUME GAME", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hostPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Case 0: Mini Game
    if (widget.type == 'mini') {
      return _buildMiniGameView();
    }

    final bool amIAnswering = GameSession().myRole == widget.answeringPlayer;
    final bool isReviewing = widget.interactionStep == 'reviewing';
    
    // Case 1: Reviewing Phase
    if (isReviewing) {
       if (amIAnswering) {
         // I answered, waiting for approval
         return _buildWaitingForApprovalView();
       } else {
         // Partner answered, I need to approve/reject
         return _buildApprovalView();
       }
    }

    // Case 2: Answering Phase
    if (amIAnswering) {
      // My turn to answer
      return _buildAnsweringView(); 
    } else {
      // Partner is answering
      return _buildPartnerAnsweringView();
    }
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

  Widget _buildWaitingForApprovalView() {
    String displayAnswer;
    if (_isBalanceGame) {
      if (widget.submittedAnswer == 'A' || widget.submittedAnswer == widget.optionA) {
        displayAnswer = 'A: ${widget.optionA}';
      } else if (widget.submittedAnswer == 'B' || widget.submittedAnswer == widget.optionB) {
        displayAnswer = 'B: ${widget.optionB}';
      } else {
        displayAnswer = widget.submittedAnswer ?? '-';
      }
    } else {
      displayAnswer = '"${widget.submittedAnswer ?? _selectedChoice}"';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_bottom, size: 50, color: AppColors.hostPrimary),
        const SizedBox(height: 20),
        Text(
          '상대방이 공감 할수 있게 설명해 주세요', 
          style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // Removed 'Please wait' subtitle as requested for cleaner UI
         const SizedBox(height: 20),
         // Show what I submitted
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '나의 답변: $displayAnswer',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerAnsweringView() {
    return SizedBox(
      width: double.infinity, // Ensure full width for centering
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.hostPrimary),
          const SizedBox(height: 30),
          Text(
            '상대방이 답변 중입니다', // "Partner is answering"
            style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.question,
              style: GoogleFonts.doHyeon(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweringView() {
    final bool isTruthGame = !_isBalanceGame;
    final String title = isTruthGame ? 'TRUTH' : 'BALANCE';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.alexandria(
            fontSize: 10, // Adjusted to 10pt as requested
            fontWeight: FontWeight.bold,
            color: AppColors.hostPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            widget.question,
            style: GoogleFonts.doHyeon(
              fontSize: 16, // Reverted to 16pt as requested
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Content
        if (isTruthGame)
          _buildTruthContent()
        else
          _buildBalanceContent(),
      ],
    );
  }

  Widget _buildApprovalView() {
    // This view is for the Reviewer (who is NOT answering)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.gavel, size: 50, color: AppColors.hostPrimary),
        const SizedBox(height: 20),
        Text(
           '상대방의 의견에 공감하나요?', // Simplified Instruction
           style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        
        // Display User's Selection/Answer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Increased vertical padding
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100), // Ensure space
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              Text(
                '제출된 답변:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12), // More gap
              // Determine type robustly
              if (_isBalanceGame) 
                 Text(
                   widget.submittedAnswer == 'A' 
                       ? 'A: ${widget.optionA}' 
                       : (widget.submittedAnswer == 'B' 
                           ? 'B: ${widget.optionB}' 
                           : (widget.submittedAnswer == widget.optionA 
                               ? 'A: ${widget.optionA}'
                               : (widget.submittedAnswer == widget.optionB 
                                   ? 'B: ${widget.optionB}'
                                   : widget.submittedAnswer.toString()))),
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                   textAlign: TextAlign.center,
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 )
              else // Truth Game
                 Text(
                   '"${widget.submittedAnswer}"',
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textDark),
                   textAlign: TextAlign.center,
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Row(
          children: [
            // Reject Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => widget.onOptionSelected('REJECT'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('비공감', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Approve Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => widget.onOptionSelected(widget.submittedAnswer ?? 'APPROVED'), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary, // Brand Color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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


  Widget _buildBalanceContent() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildOptionButton(
              context,
              label: widget.optionA,
              color: const Color(0xFF7DD3FC), // Sky Blue
              value: 'A',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildOptionButton(
              context,
              label: widget.optionB,
              color: const Color(0xFFFBCFE8), // Pink
              value: 'B',
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

  Widget _buildTruthContent() {
    // Parse answers directly from comma-separated string if simple
    // Or just use the whole string as one suggestion if no commas?
    // Assuming backend sends answers like "Yes, No, I don't know" or "Option1, Option2"
    final List<String> suggestions = widget.answer?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

    return Column(
      children: [
        // Input Field
        TextField(
          controller: _answerController,
          maxLength: 20, // Enforce 20 chars limit
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true, // Reduces height
            hintText: '답변을 입력하거나 선택하세요', 
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Minimal padding
            counterText: "",
          ),
        ),
        const SizedBox(height: 20),

        // Suggestions Chips (Horizontal Scroll, Max 4)
        if (suggestions.isNotEmpty) ...[
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
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12), // Caption size
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

        SizedBox(
          width: double.infinity,
          height: 32, // Drastically reduced from 60 to ~24-32 range as requested
          child: ElevatedButton(
            onPressed: () {
               if (_answerController.text.isEmpty) return;
               widget.onOptionSelected(_answerController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hostPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero, // Remove internal padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Smaller font
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
  }) {
    return ElevatedButton(
      onPressed: () => widget.onOptionSelected(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20), // More vertical padding for multi-line
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          height: 1.3, // Better line spacing
        ),
        textAlign: TextAlign.center,
        softWrap: true, // Enable word wrap
      ),
    );
  }
}
