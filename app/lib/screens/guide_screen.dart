import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';

class GuideScreen extends StatefulWidget {
  final String title;
  final String contentKey; // Key to fetch from Localization

  const GuideScreen({
    super.key, 
    required this.title, 
    required this.contentKey
  });

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  bool _isConfirmed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Fetch content based on key
    final String content = AppLocalizations.get(widget.contentKey) ?? "Content not found.";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontFamily: 'NURA'
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
                child: MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.alexandria(fontSize: 14, height: 1.5, color: Colors.black87),
                    strong: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    h1: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold),
                    h2: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold),
                    listBullet: GoogleFonts.alexandria(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),

          // Footer (Checkbox & Button)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Checkbox Tile
                   CheckboxListTile(
                     value: _isConfirmed,
                     onChanged: (val) {
                       setState(() {
                         _isConfirmed = val ?? false;
                       });
                     },
                     title: Text(
                       AppLocalizations.get('guide_read_confirm') ?? "I have read and understood the above.",
                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                     ),
                     controlAffinity: ListTileControlAffinity.leading,
                     contentPadding: EdgeInsets.zero,
                     activeColor: AppColors.hostPrimary,
                   ),
                   const SizedBox(height: 12),
                   
                   // Confirm Button
                   SizedBox(
                     width: double.infinity,
                     child: AnimatedButton(
                       onPressed: _isConfirmed ? () {
                         Navigator.of(context).pop();
                       } : null, // Disabled if not checked
                       
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.hostPrimary,
                         disabledBackgroundColor: Colors.grey[300],
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: Text(
                         AppLocalizations.get('guide_confirm_btn') ?? "Confirm",
                         style: const TextStyle(
                           fontSize: 16, 
                           fontWeight: FontWeight.bold,
                           color: Colors.white
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
