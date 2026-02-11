import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/localization.dart';

class QuizModal extends StatelessWidget {
  final String question;
  final String optionA;
  final String optionB;
  final Function(String) onOptionSelected;

  const QuizModal({
    super.key,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Balance Quiz',
              style: GoogleFonts.alexandria(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // Question
            Text(
              question,
              style: GoogleFonts.k2d(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.get('quiz_balance_hint'),
              style: GoogleFonts.alexandria(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),

            // Options
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    context,
                    label: optionA,
                    color: const Color(0xFF7DD3FC), // Sky Blue
                    value: 'A',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    context,
                    label: optionB,
                    color: const Color(0xFFFBCFE8), // Pink
                    value: 'B',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Close Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required String value,
  }) {
    return ElevatedButton(
      onPressed: () => onOptionSelected(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20),
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
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
