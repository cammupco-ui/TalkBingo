import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/widgets/game_history_item.dart';
import 'package:talkbingo_app/styles/app_colors.dart';

class BingoHistoryScreen extends StatelessWidget {
  const BingoHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming GameSession singleton is available and initialized
    final session = GameSession(); 

    return Scaffold(
      backgroundColor: AppColors.bgDark, // Match main app bg
      appBar: AppBar(
        title: Text("BINGO HISTORY", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: session.fetchGameHistory(), // We might want to fetch ALL here, currently limit 20
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return const Center(child: Text("No game history found.", style: TextStyle(color: Colors.white60)));
          }

          final games = snapshot.data!;

          return Container(
             margin: const EdgeInsets.only(top: 10),
             decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)], 
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
             ),
             child: ListView.separated(
               padding: const EdgeInsets.only(top: 20, bottom: 40),
               itemCount: games.length,
               separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 1, indent: 20, endIndent: 20),
               itemBuilder: (context, index) {
                 return GameHistoryItem(game: games[index]);
               },
             ),
          );
        },
      ),
    );
  }
}
