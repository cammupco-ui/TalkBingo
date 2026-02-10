import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/screens/game_setup_screen.dart';

class GameHistoryItem extends StatefulWidget {
  final Map<String, dynamic> game;
  final bool isReviewMode;

  const GameHistoryItem({
    super.key,
    required this.game,
    this.isReviewMode = false,
  });

  @override
  State<GameHistoryItem> createState() => _GameHistoryItemState();
}

class _GameHistoryItemState extends State<GameHistoryItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.game['opponent'] ?? 'Opponent';
    final date = widget.game['date'] ?? 'Unknown Date';
    final settings = widget.game['settings'] as Map<String, dynamic>?;

    // Mock Data for Visuals (replace with real data later)
    final int score = (title.length % 5) + 2; // Random-ish score 2-6
    final bool isWin = (title.length % 2) == 0; // Random-ish result
    final String resultText = isWin ? "WIN" : "LOSS";
    final Color resultColor = isWin ? const Color(0xFFE91E63) : const Color(0xFFD81B60);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameScreen(
              isReviewMode: true,
              reviewSessionId: widget.game['id'],
            ),
          )
        );
      },
      onHighlightChanged: (val) {
         if (mounted) setState(() => _isHovering = val);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            children: [
            // Avatar
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GameSetupScreen(
                    isEditMode: true,
                    initialMainRelation: settings?['relationMain'],
                    initialSubRelation: settings?['relationSub'],
                    initialIntimacyLevel: settings?['intimacyLevel'],
                    initialGender: settings?['guestGender'],
                  )),
                );
              },
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blueGrey[800],
                child: SvgPicture.asset(
                  'assets/images/logo_vector.svg', // Placeholder
                  height: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     title, 
                     style: TextStyle(
                        color: _isHovering ? const Color(0xFFFF0077) : Colors.black87,
                        fontWeight: _isHovering ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 12
                     )
                   ),
                  const SizedBox(height: 3),
                  Text(
                    "$date${settings != null && settings['intimacyLevel'] != null ? ' . Level ${settings['intimacyLevel']}' : ''}",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Score Badge
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFA1887F), // Muted brownish/grey color
                shape: BoxShape.circle,
              ),
              child: Text(
                "$score",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            
            // Result
            SizedBox(
              width: 45, // Fixed width to align badges
              child: Text(
                resultText,
                textAlign: TextAlign.center,
                style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
