import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/screens/game_screen.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/waiting_screen.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/localization.dart';
class GameSetupScreen extends StatefulWidget {
  final String? initialGender;
  final String? initialMainRelation;
  final String? initialSubRelation;
  final int? initialIntimacyLevel;
  final bool isEditMode; // Added isEditMode

  const GameSetupScreen({
    super.key,
    this.initialGender,
    this.initialMainRelation,
    this.initialSubRelation,
    this.initialIntimacyLevel,
    this.isEditMode = false,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  String? _selectedGender;
  String _selectedMainRelation = 'Friend';
  String? _selectedSubRelation;
  int _selectedIntimacyLevel = 3;

  @override
  void initState() {
    super.initState();
    GameSession().addListener(_onSessionUpdate);
    // Pre-fill if provided (Rematch)
    if (widget.initialGender != null) _selectedGender = widget.initialGender;
    if (widget.initialMainRelation != null) _selectedMainRelation = widget.initialMainRelation!;
    if (widget.initialSubRelation != null) _selectedSubRelation = widget.initialSubRelation;
    if (widget.initialIntimacyLevel != null) _selectedIntimacyLevel = widget.initialIntimacyLevel!;
    
    // Auto-Start if Rematch
    if (widget.initialGender != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show loading and trigger start automatically
        _onStartGamePressed(); 
      });
    }
  }

  // Raw Data: Friend/Family/Lover keys, then List of {ko, en} maps
  // Note: Values must match what is expected for code gen, or be mapped.
  // Current Code Gen checks: "고향친구", "Area", etc.
  // To stay safe, we will use the Dual Format "Primary (Secondary)" but switch order.
  
  final Map<String, List<Map<String, String>>> _rawRelationData = {
    'Friend': [
       {'ko': '고향친구', 'en': 'Area'},
       {'ko': '학교친구', 'en': 'School'},
       {'ko': '직장동료', 'en': 'Organization'},
       {'ko': '동네친구', 'en': 'Distance'},
    ],
    'Family': [
       {'ko': '형제', 'en': 'Brother'},
       {'ko': '자매', 'en': 'Sister'},
       {'ko': '남매', 'en': 'Siblings'},
       {'ko': '사촌', 'en': 'Cousin'},
       {'ko': '조부모', 'en': 'Grandparent'},
       {'ko': '부모/자녀', 'en': 'Parent/Child'},
    ],
    'Lover': [
       {'ko': '애인', 'en': 'Sweet'},
       {'ko': '부부', 'en': 'Spouse'},
    ],
  };

  // Helper to Generation Options based on Current Language
  List<String> _getRelationList(String category) {
      final lang = GameSession().language;
      final rawList = _rawRelationData[category] ?? [];
      
      return rawList.map((item) {
          if (lang == 'en') {
             return "${item['en']} (${item['ko']})";
          } else {
             return "${item['ko']} (${item['en']})";
          }
      }).toList();
  }

  // Convert current value (e.g., "고향친구 (Area)" -> "Area (고향친구)") if switching lang
  String? _convertSubRelation(String? currentVal, String targetLang) {
     if (currentVal == null) return null;
     
     // Find the item in ANY category that matches currentVal
     // We know the structure is "A (B)"
     for (var cat in _rawRelationData.keys) {
         final list = _rawRelationData[cat]!;
         for (var item in list) {
             final koForm = "${item['ko']} (${item['en']})";
             final enForm = "${item['en']} (${item['ko']})";
             
             if (currentVal == koForm || currentVal == enForm) {
                 // Found match. Return target format.
                 if (targetLang == 'en') return enForm;
                 else return koForm;
             }
         }
     }
     return currentVal; // Fallback
  }


  final List<Map<String, dynamic>> _intimacyLevels = [
    {
      'level': 1,
      'title': '첫 만남 (어색한 사이)',
      'description': '아직은 어색하고 서로를 탐색하는 단계'
    },
    {
      'level': 2,
      'title': '알아가는 단계',
      'description': '취향과 경험을 공유하며 자연스러운 대화가 가능한 단계'
    },
    {
      'level': 3,
      'title': '친한 사이',
      'description': '농담을 주고받으며 연애나 과거 등 민감한 주제도 이야기하는 단계'
    },
    {
      'level': 4,
      'title': '고민 상담 가능',
      'description': '서로의 약점이나 고민을 털어놓으며 깊은 유대감을 형성한 단계'
    },
    {
      'level': 5,
      'title': '깊은 신뢰',
      'description': '비밀, 재정 문제, 미래 계획 등 거의 모든 것을 공유하는 단계'
    },
  ];

  bool get _isFormValid {
    return _selectedGender != null &&
        _selectedSubRelation != null;
  }

  Future<void> _onStartGamePressed() async {
    if (_isFormValid) {
        // Cache existing Session ID (from HostSetupScreen)
        final String? existingSessionId = GameSession().sessionId;
        final String? existingInviteCode = GameSession().inviteCode;

        // Reset Game Session to ensure clean state (Fixes "Bingo Modal" on Rematch)
        GameSession().reset();

        // Restore Session ID if it existed (Start New Game Flow)
        if (existingSessionId != null) {
           GameSession().restoreSession(existingSessionId, existingInviteCode);
           GameSession().myRole = 'A'; // Re-assign Host Role
        }

        // Save data to GameSession
        final session = GameSession();
        // session.guestAge = _selectedAge; // Removed
        session.guestGender = _selectedGender;
        session.relationMain = _selectedMainRelation;
        session.relationSub = _selectedSubRelation;
        session.intimacyLevel = _selectedIntimacyLevel;

      if (widget.isEditMode) {
        Navigator.of(context).pop(); // Just save and exit
        return;
      }

      // Check for Ad Removal possibility
      if (GameSession().vp >= 200) {
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white, // Force White Background
            surfaceTintColor: Colors.transparent, // Remove M3 tint
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Consistent shape
            title: Text(
              "Remove Ads?", 
              style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            content: Text(
              "Do you want to use 200 VP to play this game without ads?\n\nCurrent VP: ${GameSession().vp}",
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), 
                child: const Text("No (Play with Ads)", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.hostPrimary, foregroundColor: Colors.white),
                child: const Text("Yes (-200 VP)"),
              ),
            ],
          ),
        );
        
        if (result == true) {
          GameSession().useVpForAdRemoval();
        }
      }

      // Show Loading Dialog
      _showLoadingDialog();

      // Save data to GameSession


      // Simulate Data Processing & Question Selection
      // 1. Generate CodeName (Simulated delay)
      await Future.delayed(const Duration(seconds: 1));
      
      // 2. Sync Host/Guest Info (Simulated delay)
      await Future.delayed(const Duration(seconds: 1));

      // 3. Fetch Questions (Direct Supabase Call)
      await session.fetchQuestionsFromSupabase();
      await Future.delayed(const Duration(seconds: 1)); // Extra delay for "Selection" feel

      // Verify Data Collection (Console Log)
      print('*** START GAME - DATA COLLECTION ***');
      print(session.toJson());
      print('CodeName: ${session.codeName}');
      print('Questions: ${session.questions}');
      print('************************************');

    if (mounted) {
        // Set Game Active local flag (mock)
        GameSession().isGameActive = true;

        Navigator.of(context).pop(); // Close dialog

        if (mounted) {
          // Host goes to WaitingScreen to create Supabase session
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaitingScreen()),
          );
        }
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFBD0558)),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.get('preparing_game'),
                  style: AppLocalizations.getTextStyle(baseStyle: GoogleFonts.alexandria(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFBD0558),
                  )),
                ),
                const SizedBox(height: 16),
                _buildLoadingStep(AppLocalizations.get('gen_codename')),
                _buildLoadingStep(AppLocalizations.get('sync_info')),
                _buildLoadingStep(AppLocalizations.get('load_questions')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show Ad on Game Setup Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = true;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          child: SvgPicture.asset(
            'assets/images/Logo Vector.svg',
            height: 36,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFBD0558)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Text(
                AppLocalizations.get('guest_settings'),
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NURA',
                  color: AppColors.hostPrimary,
                )),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 10),

            const SizedBox(height: 12),

            // Guest Info Section
            const SizedBox(height: 10),
            // Guest Info Section
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Language Selection
            _buildSectionTitle(AppLocalizations.get('language')),
            Row(
              children: [
                _buildLanguageChip('English', 'en'),
                const SizedBox(width: 8),
                _buildLanguageChip('한국어', 'ko'),
              ],
            ),
            const SizedBox(height: 12),

            // Gender Section
            _buildSectionTitle(AppLocalizations.get('gender')),
            Row(
              children: [
                _buildGenderToggle(AppLocalizations.get('male'), 'Male'),
                const SizedBox(width: 8),
                _buildGenderToggle(AppLocalizations.get('female'), 'Female'),
              ],
            ),
            const SizedBox(height: 12),

            // Relationship Section
            _buildSectionTitle(AppLocalizations.get('relationship')),
            const SizedBox(height: 10),
            Row(
              children: ['Friend', 'Family', 'Lover'].map((relation) {
                final isSelected = _selectedMainRelation == relation;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMainRelation = relation;
                          _selectedSubRelation = null; 
                        });
                      },
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFBD0558) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFBD0558) : Colors.grey,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.get(relation),
                          style: AppLocalizations.getTextStyle(baseStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Sub Relation Dropdown
            DropdownButtonFormField<String>(
              isExpanded: true, // Ensure text fits
              dropdownColor: Colors.white, 
              initialValue: _selectedSubRelation,
              items: _getRelationList(_selectedMainRelation).map((sub) {
                return DropdownMenuItem(value: sub, child: Text(sub, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (value) => setState(() => _selectedSubRelation = value),
              style: const TextStyle(fontSize: 14, color: Colors.black),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFBD0558))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                // isDense: true,
                hintStyle: TextStyle(fontSize: 14),
              ),
              hint: Text(AppLocalizations.get('select_relation')),
            ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Intimacy Section
          _buildSectionTitle(AppLocalizations.get('intimacy_level')),
            const SizedBox(height: 10),
            ..._intimacyLevels.map((levelData) => _buildIntimacyOption(levelData)),
            
            const SizedBox(height: 12),

            // Start Game Button
            ElevatedButton(
              onPressed: _isFormValid ? _onStartGamePressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD0558),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 0), // Use fixedSize instead
                fixedSize: const Size.fromHeight(44), // Strict 44px
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                widget.isEditMode ? 'SAVE' : AppLocalizations.get('start_game'),
                style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, fontFamily: 'NURA', fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.hostPrimary,
        )),
      ),
    );
  }

  Widget _buildGenderToggle(String label, String value) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = isSelected ? null : value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.hostPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.hostPrimary : Colors.grey,
            ),
          ),
          child: Text(
            label,
            style: AppLocalizations.getTextStyle(baseStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            )),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildIntimacyOption(Map<String, dynamic> data) {
    final int level = data['level'];
    final bool isSelected = _selectedIntimacyLevel == level;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Reduced bottom padding
      child: InkWell(
        onTap: () => setState(() => _selectedIntimacyLevel = level),
        borderRadius: BorderRadius.circular(8), // Slightly smaller radius
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Compact padding
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFBD0558) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFBD0558) : Colors.grey.shade300,
              width: isSelected ? 0 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 20, // Smaller checkbox
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Color(0xFFBD0558))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Level $level - ${AppLocalizations.get(data['title_key'] ?? 'level_${level}_title')}',
                  style: AppLocalizations.getTextStyle(baseStyle: TextStyle(
                    fontSize: 13, // Strict 13-14px
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSessionUpdate() {
      if (mounted) {
          setState(() {
              // Rebuild to reflect changes (like language)
          });
      }
  }

  Widget _buildLanguageChip(String label, String value) {
    // Current Language from Session
    final currentLang = GameSession().language;
    final isSelected = currentLang == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
         if (selected) {
            setState(() {
               // 1. Convert current relation if selected
               if (_selectedSubRelation != null) {
                  _selectedSubRelation = _convertSubRelation(_selectedSubRelation, value);
               }
               
               // 2. Set Language
               GameSession().setLanguage(value);
            });
         }
      },
      selectedColor: AppColors.hostPrimary,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: value == 'en'
          ? GoogleFonts.alexandria(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )
          : TextStyle(
              fontFamily: 'EliceDigitalBaeum',
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    GameSession().removeListener(_onSessionUpdate);
    super.dispose();
  }
}
