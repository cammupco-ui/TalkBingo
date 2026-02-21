import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:talkbingo_app/utils/localization.dart';

class GameSession with ChangeNotifier {
  static final GameSession _instance = GameSession._internal();
  factory GameSession() => _instance;
  
  GameSession._internal() {
      _detectLanguage();
  }

  void _detectLanguage() {
      try {
         final locale = ui.PlatformDispatcher.instance.locale;
         final allLocales = ui.PlatformDispatcher.instance.locales;
         debugPrint('🌐 [Language] Primary locale: ${locale.languageCode}_${locale.countryCode}');
         debugPrint('🌐 [Language] All locales: ${allLocales.map((l) => '${l.languageCode}_${l.countryCode}').join(', ')}');
         
         // Check primary locale first
         if (locale.languageCode == 'ko') {
           _language = 'ko';
         } else {
           // Also check all browser locales — if any is Korean, use Korean
           final hasKo = allLocales.any((l) => l.languageCode == 'ko');
           _language = hasKo ? 'ko' : 'en';
         }
         debugPrint('🌐 [Language] Selected: $_language');
      } catch (e) {
         debugPrint("Error detecting locale: $e");
      }
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  // Session Data
  String? _sessionId;
  String? get sessionId => _sessionId;
  
  void restoreSession(String id, String? code) {
    _sessionId = id;
    inviteCode = code;
    _setupRealtimeHover();
  }
  
  // Host Info
  String? hostId;
  String? hostNickname;
  String? hostAge;
  String? hostGender; // 'Male', 'Female'
  String? hostHometownProvince;
  String? hostHometownCity;
  bool? hostConsent;
  // New Enhanced Profile Fields
  String? hostSns;
  String? hostBirthDate; // YYYY-MM-DD
  String? hostAddress;
  String? hostPhone;
  bool? hostRegionConsent;
  
  // Guest Info
  String? guestId;
  String? guestNickname;
  String? guestAge;
  String? guestGender; // 'Male', 'Female'
  String? guestHometownProvince;
  String? guestHometownCity;
  bool? guestConsent;
  
  String? relationMain = 'Friend';
  String? relationSub;
  int _intimacyLevel = 3;
  int get intimacyLevel => _intimacyLevel;
  set intimacyLevel(int value) {
    if (value > 5) {
       debugPrint("⚠️ WARNING: Suspicious Intimacy Level set: $value");
       debugPrint(StackTrace.current.toString());
    }
    _intimacyLevel = value;
  }

  // Targeting Info (Persisted for Rematch)
  String? persistedHostGender;
  String? persistedGuestGender;
  String? persistedRelationMain;
  String? persistedRelationSub;
  int? persistedIntimacyLevel;

  // Question Cache
  List<String>? cachedQuestions;
  List<Map<String, dynamic>>? cachedOptions;

  // Payment Info
  String? paymentHolderName;
  String? paymentCardNumber;
  String? paymentExpiry;
  String? paymentCvv;

  // Game Logic Data
  String? codeName;
  List<String> questions = [];
  List<Map<String, dynamic>> options = [];
  
  String? inviteCode;
  String? pendingInviteCode; // Used for deep linking / joining
  
  String myRole = ''; // 'A' (Host) or 'B' (Guest)
  String gameStatus = 'waiting'; // waiting, playing, paused, finished
  String currentTurn = 'A'; 
  bool get isPaused => gameStatus == 'paused';
  
  // --- Mini-Game Round-Robin ---
  static const List<String> _miniGameTypes = ['mini_target', 'mini_penalty'];
  int _miniGameIndex = 0;

  /// Returns the next mini-game type in round-robin order.
  /// When more types are added to [_miniGameTypes], they rotate automatically.
  String _nextMiniGameType() {
    final type = _miniGameTypes[_miniGameIndex % _miniGameTypes.length];
    _miniGameIndex++;
    return type;
  }

  // 5x5 Grid (25 tiles)
  List<String> _tileOwnership = List.filled(25, ''); 
  List<String> get tileOwnership => _tileOwnership;

  // Track Guest Join Status locally
  String? _lastKnownGuestNickname;

  // New Method to Sync Guest Info
  Future<void> updateGuestProfile(String nickname) async {
    guestNickname = nickname;
    notifyListeners();
    await _syncGameState();
  }

  // Tracking
  int completedLines = 0; // For local display/tracking

  // Interaction
  Map<String, dynamic>? interactionState;
  
  // Points & Rewards (GP/VP Dual Currency)
  int gp = 0; // Game Points — earned through gameplay, never spent
  int vp = 0; // Value Points — purchased via IAP or rewarded ads
  
  // Trust Score
  double hostTrustScore = 5.0; // Average
  int hostTrustCount = 0; // Number of ratings
  double ts = 0.0;
  bool adFree = false;
  bool permanentAdFree = false; // Permanent ad removal (8,000 VP)
  int dailyRewardedAdCount = 0; // Daily rewarded ad views (max 10)
  String lastRewardedAdDate = ''; // YYYY-MM-DD for daily reset
  List<Map<String, dynamic>> pointHistory = [];

  // Chat
  List<Map<String, dynamic>> messages = [];
  RealtimeChannel? _gameChannel;
  bool isGameActive = false;
  
  // Turn Tracking
  int turnCount = 1;
  Map<String, int> lockedTurns = {}; // Key: Index String, Value: Turn Count when locked
  
  // Hover Sync (Real-time Broadcast)
  ValueNotifier<int?> remoteHoverIndex = ValueNotifier(null);
  Timer? _hoverDebounce;

  // Two-Tap Preview System
  ValueNotifier<int?> previewCellIndex = ValueNotifier(null);
  ValueNotifier<int?> remotePreviewCellIndex = ValueNotifier(null);
  String? previewLabel;       // B, T, ⚔️, 🔒
  String? remotePreviewLabel; // opponent's preview label

  // Bingo Line Calculation (Live)
  int get bingoLines {
    int lines = 0;
    // Rows
    for (int row = 0; row < 5; row++) {
       if ([0,1,2,3,4].every((c) => _tileOwnership[row * 5 + c] == myRole)) lines++;
    }
    // Cols
    for (int col = 0; col < 5; col++) {
       if ([0,1,2,3,4].every((r) => _tileOwnership[r * 5 + col] == myRole)) lines++;
    }
    // Diagonals
    if ([0,6,12,18,24].every((i) => _tileOwnership[i] == myRole)) lines++;
    if ([4,8,12,16,20].every((i) => _tileOwnership[i] == myRole)) lines++;
    
    return lines;
  }

  
  // --- Methods ---

  // Aliases for compatibility
  Future<void> fetchQuestionsFromBackend() async {
    return fetchQuestionsFromSupabase();
  }

  Future<void> fetchQuestionsFromSupabase() async {
    // Determine genders for CodeName if not set from Profile
    // Note: We map 'Female' to 'F', 'Male' to 'M'.
    String hGender = (hostGender == 'Female') ? 'F' : 'M'; 
    String gGender = (guestGender == 'Female') ? 'F' : 'M';
    
    if (codeName == null) {
      // Standard Logic for Base Code
      String relCode = 'B'; 
      if (relationMain == 'Family') relCode = 'Fa';
      if (relationMain == 'Lover') relCode = 'Lo';
      
      String subRel = 'Ar'; // Default
      if (relationSub != null) {
        if (relationSub!.contains('고향친구')) subRel = 'Ar';
        else if (relationSub!.contains('학교친구')) subRel = 'Sc';
        else if (relationSub!.contains('직장동료')) subRel = 'Or';
        else if (relationSub!.contains('동네친구')) subRel = 'Dc';
        else if (relationSub!.contains('형제')) subRel = 'Br';
        else if (relationSub!.contains('자매')) subRel = 'Si';
        else if (relationSub!.contains('남매')) subRel = 'Sb';
        else if (relationSub!.contains('사촌')) subRel = 'Co';
        else if (relationSub!.contains('조부모')) subRel = 'Gp';
        else if (relationSub!.contains('부모')) subRel = 'Fs';
        else if (relationSub!.contains('애인')) subRel = 'Sw';
        else if (relationSub!.contains('부부')) subRel = 'Hw';
      }
      
      // Parent-Child Logic Handling
      if (relationMain == 'Family' && subRel == 'Fs') {
         if (hGender == 'F' && gGender == 'F') subRel = 'Md'; // Mother-Daughter
         else if (hGender == 'F' && gGender == 'M') subRel = 'Ms'; // Mother-Son
         else if (hGender == 'M' && gGender == 'F') subRel = 'Fd'; // Father-Daughter
         else subRel = 'Fs'; // Father-Son (M-M)
      }

      // Base CodeName (used for logging/reference)
      codeName = '$hGender-$gGender-$relCode-$subRel-L$intimacyLevel';
      debugPrint('*** [Local CodeName Gen] Generated Base: $codeName ***');
    }

    // --- INTERSECTION MATCHING LOGIC ---
    // Problem: M-F game should not show M-only questions when F is answering, or F-only when M.
    // Solution: Fetch intersection. Valid questions must satisfy BOTH constraints.
    // MP (Respondent) Constraint: Must be hGender OR '*'
    // CP (Partner) Constraint: Must be gGender OR '*'
    
    final parts = codeName!.split('-'); // [0]M-[1]F-[2]B-[3]Sub-[4]Lvl
    final rel = parts[2];
    final sub = parts[3];
    final lvl = parts[4];

    List<String> validMPs = [hGender, '*'];
    List<String> validCPs = [gGender, '*'];
    
    List<String> candidateCodes = [];
    
    // Generate Permutations
    for (var mp in validMPs) {
        for (var cp in validCPs) {
            // Pattern 1: Exact SubRel
            candidateCodes.add('$mp-$cp-$rel-$sub-$lvl');
            // Pattern 2: Wildcard SubRel (Broad)
            candidateCodes.add('$mp-$cp-$rel-*-$lvl');
        }
    }
    
    // Safe Net (Total Wildcard) - if strictly needed
    candidateCodes.add('*-*-*-*-*');

    // Deduplicate
    candidateCodes = candidateCodes.toSet().toList();

    // Priority Definitions for Sorting
    // Primary: The specific context codes generated above
    final Set<String> primarySet = Set.from(candidateCodes);
    
    // Fallback: Add broad safety nets if not already present
    // We add them to candidateCodes for the QUERY, but we know they are low priority
    final safeNet = '*-*-*-*-*';
    if (!candidateCodes.contains(safeNet)) {
        candidateCodes.add(safeNet);
    }
    
    // Broad Relationship Fallback (e.g. just Relationship match, ignore sub/intimacy if desperate)
    // candidateCodes.add('*-*-${parts[2]}-*-*'); // Optional

    debugPrint('Fetching questions for Intersection Candidates (Priority+Fallback): $candidateCodes');

    try {
      // --- TYPE-SPLIT RANDOM FETCH (via Supabase RPC) ---
      // Each query uses ORDER BY random() on the server to avoid
      // always fetching the same questions in insertion order.

      final specificCodes = candidateCodes.where((c) => c != '*-*-*-*-*').toList();
      
      // Phase 1: Relationship-specific questions (Balance + Truth separately)
      List<dynamic> specificBalance = [];
      List<dynamic> specificTruth = [];
      
      if (specificCodes.isNotEmpty) {
        // Fetch Balance questions (random)
        try {
          specificBalance = await _supabase.rpc('get_random_questions', params: {
            'p_codes': specificCodes,
            'p_type_prefix': 'B',
            'p_limit': 40,
          });
        } catch (e) {
          debugPrint('⚠️ RPC balance fetch failed, using fallback: $e');
        }
        
        // Fetch Truth questions (random)
        try {
          specificTruth = await _supabase.rpc('get_random_questions', params: {
            'p_codes': specificCodes,
            'p_type_prefix': 'T',
            'p_limit': 40,
          });
        } catch (e) {
          debugPrint('⚠️ RPC truth fetch failed, using fallback: $e');
        }
      }
      
      debugPrint('📊 Specific: ${specificBalance.length} balance + ${specificTruth.length} truth');

      // Phase 2: Wildcard questions (Balance + Truth separately)
      List<dynamic> wildcardBalance = [];
      List<dynamic> wildcardTruth = [];
      
      try {
        wildcardBalance = await _supabase.rpc('get_random_wildcard_questions', params: {
          'p_type_prefix': 'B',
          'p_limit': 20,
        });
      } catch (e) {
        debugPrint('⚠️ RPC wildcard balance failed: $e');
      }
      
      try {
        wildcardTruth = await _supabase.rpc('get_random_wildcard_questions', params: {
          'p_type_prefix': 'T',
          'p_limit': 20,
        });
      } catch (e) {
        debugPrint('⚠️ RPC wildcard truth failed: $e');
      }
      
      debugPrint('📊 Wildcard: ${wildcardBalance.length} balance + ${wildcardTruth.length} truth');

      // --- COMBINE WITH DEDUPLICATION ---
      final seenIds = <String>{};
      List<dynamic> combined = [];
      
      // Helper: add unique questions
      void addUnique(List<dynamic> source) {
        for (var q in source) {
          final qId = q['id'].toString();
          if (seenIds.add(qId)) combined.add(q);
        }
      }
      
      // Priority: specific relationship questions first, then wildcards
      addUnique(specificBalance);
      addUnique(specificTruth);
      addUnique(wildcardBalance);
      addUnique(wildcardTruth);
      
      debugPrint('📊 Total unique questions: ${combined.length}');
      
      // --- FALLBACK: Direct query if RPC functions not yet deployed ---
      if (combined.length < 25) {
        debugPrint('⚠️ RPC returned too few (${combined.length}). Falling back to direct query...');
        final fallbackQuestions = await _supabase
            .from('questions')
            .select()
            .overlaps('code_names', candidateCodes)
            .eq('is_published', true)
            .limit(120);
        
        fallbackQuestions.shuffle();
        addUnique(fallbackQuestions);
        debugPrint('📊 After fallback: ${combined.length} total');
      }
      
      // Final shuffle for random board layout
      combined.shuffle();
      
      List<dynamic> loadedQuestions = combined;

      // Ensure we have enough questions for a 5x5 Grid (25)
      if (loadedQuestions.length >= 25) {
          await _parseAndSetQuestions(loadedQuestions);
      } else {
        debugPrint('⚠️ Only ${loadedQuestions.length} questions found. Using Fallback Mock.');
        _generateFallbackQuestions();
        gameStatus = 'playing'; 
        await _syncGameState(); 
      }
    } catch (e) {
      debugPrint('Error fetching questions from Supabase: $e');
      _generateFallbackQuestions();
      gameStatus = 'playing';
      await _syncGameState();
    }
  }

  Future<void> _processQuestionsWithRatioAndUniqueness(List<dynamic> rawQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    
    // History Loading Logic...
    Map<String, String> playedDates = {};
    if (prefs.containsKey('played_questions_dates')) {
       try {
         playedDates = Map<String, String>.from(jsonDecode(prefs.getString('played_questions_dates')!));
       } catch (e) { /* ignore */ }
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // 1. Filter Uniqueness
    List<dynamic> pool = rawQuestions.where((q) {
      final qId = q['id'].toString();
      if (!playedDates.containsKey(qId)) return true;
      final lastPlayedStr = playedDates[qId];
      if (lastPlayedStr == null) return true;
      final lastPlayed = DateTime.tryParse(lastPlayedStr);
      if (lastPlayed == null) return true;
      return lastPlayed.isBefore(thirtyDaysAgo);
    }).toList();

    // FAILSAFE: If filtering removed everything (user played all available questions),
    // we must reuse them rather than freezing.
    if (pool.isEmpty) {
       debugPrint('⚠️ All questions played recently. Resetting pool to raw questions to avoid freeze.');
       pool = List.from(rawQuestions);
    }

    // 2. Handle insufficient pool size
    // We aim for 50 (25 Main + 25 Reserve), but NEVER duplicate questions.
    if (pool.isEmpty) {
      debugPrint('❌ Critical Error: Pool is empty. Using fallback mock.');
      _generateFallbackQuestions();
      gameStatus = 'playing';
      await _syncGameState();
      return;
    }
    
    if (pool.length < 50) {
      debugPrint('⚠️ Pool size (${pool.length}) < 50. Using available questions without duplication.');
      // Do NOT duplicate — use what we have. fillList() will handle shortages gracefully.
    }
    
    // 3. Parse & Segregate (Maintain Order for Priority)
    List<Map<String, dynamic>> balanceList = [];
    List<Map<String, dynamic>> truthList = [];

    for (var q in pool) {
      final parsed = _parseSingleQuestion(q);
      if (parsed['options']['type'] == 'truth') {
        truthList.add(parsed);
      } else {
        balanceList.add(parsed);
      }
    }

    // 4. Select up to 50 (25 Main + up to 25 Reserve) — NO DUPLICATES
    List<Map<String, dynamic>> mainSelected = [];
    List<Map<String, dynamic>> reserveSelected = [];
    final Set<String> usedIds = {}; // Track used question IDs across main+reserve
    
    // Helper to extract Top N unique items (Preserving High Priority)
    void fillList(List<Map<String, dynamic>> targetList, int maxCount) {
        int tCount = (maxCount * 0.52).ceil();  // ~52% truth
        int bCount = maxCount - tCount;          // ~48% balance
        
        for (int i = 0; i < tCount; i++) {
            // Find next unused truth question
            final idx = truthList.indexWhere((q) => !usedIds.contains(q['id'].toString()));
            if (idx != -1) {
              usedIds.add(truthList[idx]['id'].toString());
              targetList.add(truthList.removeAt(idx));
            } else {
              // Fallback to unused balance
              final bIdx = balanceList.indexWhere((q) => !usedIds.contains(q['id'].toString()));
              if (bIdx != -1) {
                usedIds.add(balanceList[bIdx]['id'].toString());
                targetList.add(balanceList.removeAt(bIdx));
              }
            }
        }
        for (int i = 0; i < bCount; i++) {
            final idx = balanceList.indexWhere((q) => !usedIds.contains(q['id'].toString()));
            if (idx != -1) {
              usedIds.add(balanceList[idx]['id'].toString());
              targetList.add(balanceList.removeAt(idx));
            } else {
              final tIdx = truthList.indexWhere((q) => !usedIds.contains(q['id'].toString()));
              if (tIdx != -1) {
                usedIds.add(truthList[tIdx]['id'].toString());
                targetList.add(truthList.removeAt(tIdx));
              }
            }
        }
        
        // Shuffle the RESULT list so the board layout is random, 
        // but the CONTENTS are the high-priority ones we just picked.
        targetList.shuffle();
    }
    
    fillList(mainSelected, 25); // First 25 (Best Quality)
    fillList(reserveSelected, 25); // Next 25 (Next Best, no overlap with main)
    
    // 5. Assign to Game Session

    // Structure: 25 items in `questions` list (Main Content).
    // `options` list will store Main Details + Reserve Details.
    
    questions = [];
    options = [];
    
    for (int i=0; i<25; i++) {
        var main = (i < mainSelected.length) ? mainSelected[i] : mainSelected[0]; // Safety
        var reserve = (i < reserveSelected.length) ? reserveSelected[i] : main; // Safety fallback
        
        questions.add(main['content'] as String);
        
        var opt = main['options'] as Map<String, dynamic>;
        
        // Inject Multilingual Content for Dynamic Switching
        opt['content_raw'] = main['content'];
        opt['content_en_raw'] = main['content_en'];
        
        // Inject Reserve
        opt['reserve'] = {
            'content': reserve['content'],
            'options': reserve['options']
        };
        options.add(opt);
        
        // Update Played Date (for Main only? or both? Let's mark both as 'exposed')
        final nowStr = DateTime.now().toIso8601String();
        playedDates[main['id'].toString()] = nowStr;
        playedDates[reserve['id'].toString()] = nowStr;
    }

    await prefs.setString('played_questions_dates', jsonEncode(playedDates));

    debugPrint('✅ Balanced Selection: 25 Main + 25 Reserve allocated.');

    gameStatus = 'playing';
    await _syncGameState();
  }

  // Language Support
  String _language = 'en'; // Default
  String get language => _language;
  
  void setLanguage(String lang) {
    if (lang != 'ko' && lang != 'en') return;
    _language = lang;
    notifyListeners();
  }

  // Dynamic Localization Getter
  Map<String, String> getLocalizedContent(int index) {
     if (index < 0 || index >= options.length) return {};
     
     final opt = options[index];
     final bool isEn = _language == 'en';
     
     // 1. Question Content — resolve gender variants first, then fallback to raw content
     String q = opt['content_raw'] ?? '';
     if (isEn && opt['content_en_raw'] != null && (opt['content_en_raw'] as String).isNotEmpty) {
        q = opt['content_en_raw'];
     }
     
     // Gender Variant Resolution (matches _resolveQuestionText logic in game_screen.dart)
     final variants = isEn ? opt['variants_en'] : opt['variants'];
     if (variants != null && variants is Map && variants.isNotEmpty) {
        final isHostTurn = (currentTurn == 'A');
        
        String norm(String? g) {
          if (g == null || g.isEmpty) return 'm';
          final low = g.toLowerCase();
          if (low.startsWith('f') || low == 'female') return 'f';
          return 'm';
        }
        final hGen = norm(hostGender);
        final gGen = norm(guestGender);
        
        // Attacker speaks to Defender
        String attacker = isHostTurn ? hGen : gGen;
        String defender = isHostTurn ? gGen : hGen;
        
        final key = "var_${attacker}_${defender}";
        if (variants[key] != null && variants[key].toString().isNotEmpty) {
          q = variants[key].toString();
        }
     }
     
     // 2. Options (A/B)
     String a = opt['A'] ?? '';
     String b = opt['B'] ?? '';
     
     if (isEn) {
        if (opt['A_en'] != null && (opt['A_en'] as String).isNotEmpty) a = opt['A_en'];
        if (opt['B_en'] != null && (opt['B_en'] as String).isNotEmpty) b = opt['B_en'];
     }
     
     // 3. Truth Answer Hints
     String answer = opt['answer']?.toString() ?? '';
     if (isEn && opt['answer_en'] != null && (opt['answer_en'] as String).isNotEmpty) {
        answer = opt['answer_en'];
     }
     
     return {
       'q': q,
       'A': a, 
       'B': b,
       'answer': answer,
     };
  }

  Map<String, dynamic> _parseSingleQuestion(dynamic q) {
      // 1. Content: Check Language Preference
      String content = q['content'] as String;
      if (_language == 'en' && q['content_en'] != null && (q['content_en'] as String).isNotEmpty) {
          content = q['content_en'] as String;
      }
      
      // 2. Options Extraction (Flattened Schema Support)
      // Check top-level columns first (New Schema)
      String optA = q['choice_a']?.toString() ?? '';
      String optB = q['choice_b']?.toString() ?? '';
      String answers = q['answers']?.toString() ?? '';
      String optAEn = q['choice_a_en']?.toString() ?? '';
      String optBEn = q['choice_b_en']?.toString() ?? '';
      String answersEn = q['answers_en']?.toString() ?? '';

      // Fallback to 'details' JSON if top-level is empty (Old Schema or Not Migrated)
      // Prefer 'details_en' column if exists for English fallback
      dynamic rawDetails = q['details'];
      dynamic rawDetailsEn = q['details_en'];

      final details = (rawDetails is Map) ? rawDetails : (rawDetails is String ? jsonDecode(rawDetails) : {});
      final detailsEn = (rawDetailsEn is Map) ? rawDetailsEn : (rawDetailsEn is String ? jsonDecode(rawDetailsEn) : {});
      
      // Korean Fallbacks
      if (optA.isEmpty) optA = details['choice_a']?.toString() ?? details['A']?.toString() ?? details['a']?.toString() ?? '';
      if (optB.isEmpty) optB = details['choice_b']?.toString() ?? details['B']?.toString() ?? details['b']?.toString() ?? '';
      if (answers.isEmpty) answers = details['answers']?.toString() ?? '';

      // English Fallbacks
      if (optAEn.isEmpty) optAEn = detailsEn['choice_a']?.toString() ?? '';
      if (optBEn.isEmpty) optBEn = detailsEn['choice_b']?.toString() ?? '';
      if (answersEn.isEmpty) answersEn = detailsEn['answers']?.toString() ?? '';

      // Normalize Type
      String? qId = q['q_id']?.toString();
      String? dbType = q['type']?.toString();
      String normalizedType = 'balance'; // Default

      if (qId != null && qId.startsWith('T')) {
         normalizedType = 'truth';
      } else if (qId != null && qId.startsWith('B')) {
         normalizedType = 'balance';
      } else if (dbType != null && dbType.isNotEmpty) {
         if (dbType.toUpperCase() == 'T') normalizedType = 'truth';
         else if (dbType.toUpperCase() == 'B') normalizedType = 'balance';
         else normalizedType = dbType.toLowerCase();
      } else {
         if (optA.isEmpty && optB.isEmpty) {
            normalizedType = 'truth';
         } else {
            normalizedType = 'balance';
         }
      }

      // 3. Parse Gender Variants (JSONB)
      // Expecting: { "var_m_f": "...", "var_f_m": "...", ... }
      Map<String, String> variants = {};
      Map<String, String> variantsEn = {};

      try {
        if (q['gender_variants'] != null) {
          final rawVariants = q['gender_variants'];
          if (rawVariants is Map) {
             variants = Map<String, String>.from(rawVariants.map((k, v) => MapEntry(k.toString(), v.toString())));
          } else if (rawVariants is String) {
             variants = Map<String, String>.from(jsonDecode(rawVariants));
          }
        }
        
        // Parse English Variants
        if (q['gender_variants_en'] != null) {
          final rawVariantsEn = q['gender_variants_en'];
          if (rawVariantsEn is Map) {
             variantsEn = Map<String, String>.from(rawVariantsEn.map((k, v) => MapEntry(k.toString(), v.toString())));
          } else if (rawVariantsEn is String) {
             variantsEn = Map<String, String>.from(jsonDecode(rawVariantsEn));
          }
        }
      } catch (e) {
        debugPrint('Error parsing gender_variants: $e');
      }
      
      // Use 'game_code' from details if needed
      String gameCode = details['game_code']?.toString() ?? '';

      return {
        'id': q['id']?.toString() ?? '',
        'content': content,
        'content_en': q['content_en']?.toString() ?? '',
        'gender_variants': variants, 
        'gender_variants_en': variantsEn,
        'options': {
          'type': normalizedType,
          'A': optA,
          'B': optB,
          'A_en': optAEn,
          'B_en': optBEn,
          'answer': answers,
          'answer_en': answersEn,
          'game_code': gameCode,
          'variants': variants, 
          'variants_en': variantsEn, 
        }
      };
  }

  // Legacy method kept if needed but redirected
  Future<void> _parseAndSetQuestions(List<dynamic> loadedQuestions) async {
      await _processQuestionsWithRatioAndUniqueness(loadedQuestions);
  }

  void _generateFallbackQuestions() {
    debugPrint('Using fallback mock data');
    questions = List.generate(25, (index) => 'Fallback Question ${index + 1}');
    options = List.generate(25, (index) => {
      'type': 'B',
      'A': 'Fallback A',
      'B': 'Fallback B',
      'answer': '',
    });
  }
  
  // --- Persistence ---

  // --- Persistence ---

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Try to fetch from Supabase first if logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        // Fetch from 'profiles' table
        final data = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        
        if (data != null) {
          debugPrint("✅ Loaded Profile from Supabase: ${data['nickname']}");
          hostNickname = data['nickname'];
          hostAge = data['age']?.toString();
          hostGender = data['gender'];
          hostHometownProvince = data['hometown'];
          hostHometownCity = data['location'];
          
          
          // Sync back to Prefs so offline works next time
          await saveProfileLocalOnly(); 
        }
      } catch (e) {
        debugPrint("⚠️ Error fetching profile from Supabase: $e");
        // Fallback to Prefs will happen below if variables are still null?
        // Actually, if we fail to fetch, we should probably trust Prefs as cache.
      }
    }

    // 2. Load from Prefs (Fallback or Offline)
    // Only overwrite if null (meaning DB didn't provide it)
    hostNickname ??= prefs.getString('hostNickname');
    hostAge ??= prefs.getString('hostAge');
    hostGender ??= prefs.getString('hostGender');
    hostHometownProvince ??= prefs.getString('hostHometownProvince');
    hostHometownCity ??= prefs.getString('hostHometownCity');
    hostConsent ??= prefs.getBool('hostConsent');
    
    hostSns ??= prefs.getString('hostSns');
    hostBirthDate ??= prefs.getString('hostBirthDate');
    hostAddress ??= prefs.getString('hostAddress');
    hostPhone ??= prefs.getString('hostPhone');
    hostRegionConsent ??= prefs.getBool('hostRegionConsent');
    
    // Also load points if persisted
    gp = prefs.getInt('gp') ?? prefs.getInt('vp') ?? 0; // Migration fallback: read old 'vp' key
    vp = prefs.getInt('vp_paid') ?? prefs.getInt('cp') ?? 0; // 'vp_paid' avoids collision with old 'vp' key
    permanentAdFree = prefs.getBool('permanentAdFree') ?? false;
    dailyRewardedAdCount = prefs.getInt('dailyRewardedAdCount') ?? 0;
    lastRewardedAdDate = prefs.getString('lastRewardedAdDate') ?? '';
    
    // Trust Score
    hostTrustScore = prefs.getDouble('hostTrustScore') ?? 5.0; 
    hostTrustCount = prefs.getInt('hostTrustCount') ?? 0;

    await loadPaymentInfo(); 
    
    // Load History
    final historyJson = prefs.getString('pointHistory');
    if (historyJson != null) {
      try {
        final List<dynamic> historyList = jsonDecode(historyJson);
        pointHistory = historyList.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint("Error loading history: $e");
      }
    }
    
    notifyListeners();
  }

  Future<void> saveProfile() async {
    // 1. Save locally first
    await saveProfileLocalOnly();

    // 2. Sync to Supabase if logged in
    final user = _supabase.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'updated_at': DateTime.now().toIso8601String(),
          'nickname': hostNickname,
          'age': hostAge != null ? int.tryParse(hostAge!) : null,
          'gender': hostGender,
          'hometown': hostHometownProvince,
          'location': hostHometownCity,
        });
        debugPrint("✅ Profile synced to Supabase");
      } catch (e) {
        debugPrint("❌ Error syncing profile to Supabase: $e");
      }
    }
  }

  Future<void> saveProfileLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    if (hostNickname != null) await prefs.setString('hostNickname', hostNickname!);
    if (hostAge != null) await prefs.setString('hostAge', hostAge!);
    if (hostGender != null) await prefs.setString('hostGender', hostGender!);
    if (hostHometownProvince != null) await prefs.setString('hostHometownProvince', hostHometownProvince!);
    if (hostHometownCity != null) await prefs.setString('hostHometownCity', hostHometownCity!);
    if (hostConsent != null) await prefs.setBool('hostConsent', hostConsent!);
    
    if (hostSns != null) await prefs.setString('hostSns', hostSns!);
    if (hostBirthDate != null) await prefs.setString('hostBirthDate', hostBirthDate!);
    if (hostAddress != null) await prefs.setString('hostAddress', hostAddress!);
    if (hostPhone != null) await prefs.setString('hostPhone', hostPhone!);
    if (hostRegionConsent != null) await prefs.setBool('hostRegionConsent', hostRegionConsent!);
    
    await prefs.setInt('gp', gp);
    await prefs.setInt('vp_paid', vp);
    await prefs.setBool('permanentAdFree', permanentAdFree);
    await prefs.setInt('dailyRewardedAdCount', dailyRewardedAdCount);
    await prefs.setString('lastRewardedAdDate', lastRewardedAdDate);
    
    await prefs.setDouble('hostTrustScore', hostTrustScore);
    await prefs.setInt('hostTrustCount', hostTrustCount);

    await prefs.setString('pointHistory', jsonEncode(pointHistory));
  }

  // --- Legacy Wrappers (Backward Compatibility) ---
  Future<void> loadHostInfoFromPrefs() => loadProfile();
  Future<void> saveHostInfoToPrefs() => saveProfile();

  Future<void> loadPaymentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    paymentHolderName = prefs.getString('paymentHolderName');
    paymentCardNumber = prefs.getString('paymentCardNumber');
    paymentExpiry = prefs.getString('paymentExpiry');
    paymentCvv = prefs.getString('paymentCvv'); // Note: In real app, use SecureStorage
    notifyListeners();
  }

  Future<void> savePaymentInfo(String holder, String number, String expiry, String cvv) async {
    final prefs = await SharedPreferences.getInstance();
    // In real app, use flutter_secure_storage
    await prefs.setString('paymentHolderName', holder);
    await prefs.setString('paymentCardNumber', number);
    await prefs.setString('paymentExpiry', expiry);
    await prefs.setString('paymentCvv', cvv);
    
    paymentHolderName = holder;
    paymentCardNumber = number;
    paymentExpiry = expiry;
    paymentCvv = cvv;
    notifyListeners();
  }


  // --- Supabase Realtime Logic ---

  // --- History Logic ---

  Future<List<Map<String, dynamic>>> fetchGameHistory() async {
      try {
        var user = _supabase.auth.currentUser;
        if (user == null) {
          // Attempt silent sign-in if needed, or return empty
           return [];
        }

        final myId = user.id;

        // Query: status == 'finished' AND (mp_id == me OR cp_id == me)
        final response = await _supabase.from('game_sessions')
            .select()
            .eq('status', 'finished')
            .or('mp_id.eq.$myId,cp_id.eq.$myId')
            .order('created_at', ascending: false) // Newest first
            .limit(20); // Limit for now

        final List<Map<String, dynamic>> results = [];

        for (var row in response) {
           final gameState = row['game_state'] ?? {};
           final dateStr = (row['created_at'] as String).split('T').first;
           
           // Determine Role in that game
           final bool amIHost = (row['mp_id'] == myId);
           final String opponentName = amIHost 
               ? (gameState['guestNickname'] ?? 'Guest') 
               : (gameState['hostNickname'] ?? 'Host');
           
           // Determine Win/Loss (Simple logic based on ownership or pre-calc?)
           // Ideally 'winner' field in DB, but we can check state if needed.
           // For now, let's just show "Date / Opponent".
           // Or we can parse 'winner' if we saved it? We haven't explicitly saved 'winner' column yet.
           // We'll rely on what's in game_state if available, or just show "Completed".
           
           results.add({
             'id': row['id'],
             'date': dateStr,
             'opponent': opponentName,
             'role': amIHost ? 'Host' : 'Guest',
             'settings': {
                'relationMain': gameState['relationMain'],
                'relationSub': gameState['relationSub'],
                'intimacyLevel': gameState['intimacyLevel'],
                'guestGender': gameState['guestGender'], 
             }
           });
        }
        return results;
      } catch (e) {
        debugPrint("Error fetching history: $e");
        return [];
      }
  }

  void generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    inviteCode = List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
    notifyListeners();
  }

  Future<bool> createGame() async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        final authResponse = await _supabase.auth.signInAnonymously();
        user = authResponse.user;
      }
      
      if (user == null) {
        debugPrint('Host Login Failed');
        return false;
      }

      if (inviteCode == null || inviteCode!.length != 6) {
        generateInviteCode();
      }
      
      final response = await _supabase.from('game_sessions').insert({
        'invite_code': inviteCode,
        'mp_id': user.id,
        'status': 'waiting',
      }).select().single();

      _sessionId = response['id'];
      hostId = user.id;
      myRole = 'A'; // Host
      
      _subscribeToGame();
      debugPrint('Game Created: $inviteCode (Session: $_sessionId)');
      return true;
    } catch (e) {
      debugPrint('Error creating game: $e');
      return false;
    }
  }

  // Load local/historical data for Review Mode
  Future<void> loadReviewSession(Map<String, dynamic> sessionData) async {
    // 1. Reset current state to avoid mixing
    reset(); 
    
    // 2. Parse ID and basic info
    _sessionId = sessionData['id'];
    
    // 3. Parse Game State (which contains messages, board, etc.)
    // Note: fetchGameHistory logic extracts 'settings', but we might need the full payload.
    // However, the `sessionData` passed from Home might just be the summary we built.
    // We need the FULL game_state from DB if we want to show messages/board.
    // So let's fetch it again here to be safe and complete.
    
    try {
      final response = await _supabase.from('game_sessions')
          .select()
          .eq('id', _sessionId!)
          .single();
          
      _loadFromMap(response); // Re-use existing parsing logic
      
      // Mark as Review Mode (maybe just a flag in GameScreen, but helpful here too?)
      // We don't subscribe to realtime changes.
      debugPrint("Loaded Review Session: $_sessionId");
    } catch (e) {
      debugPrint("Error loading review session: $e");
    }
  }

  Future<bool> joinGame(String code) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        final authResponse = await _supabase.auth.signInAnonymously();
        user = authResponse.user;
      }
      
      if (user == null) return false;

      // Use RPC to bypass RLS
      final res = await _supabase.rpc('join_game_by_code', params: {
        'code_input': code,
        'guest_id': user.id
      });
      
      if (res['success'] == true) {
         final data = res['data'];
         _sessionId = data['id'];
         inviteCode = code;
         guestId = user.id;
         myRole = 'B'; // Guest
         
         _loadFromMap(data);
         _subscribeToGame();
         debugPrint('Joined Game via RPC! Session: $_sessionId');
         return true;
      } else {
         throw res['error'] ?? 'Join Failed';
      }
    } catch (e) {
      debugPrint('Error joining game: $e');
      throw e;
    }
  }

  Future<void> refreshSession() async {
    if (_sessionId == null) return;
    try {
      final data = await _supabase
          .from('game_sessions')
          .select()
          .eq('id', _sessionId!)
          .single();
      _loadFromMap(data);
      notifyListeners(); // Ensure UI updates after refresh
    } catch (e) {
      debugPrint('Error refreshing session: $e');
    }
  }

    // Broadcast Stream
  final _gameEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get gameEvents => _gameEventController.stream;
  
  // TEST HARNESS ONLY: Inject simulated network event
  void injectTestEvent(Map<String, dynamic> event) {
     _gameEventController.add(event);
  }

  Future<void> sendGameEvent(Map<String, dynamic> payload) async {
    if (_gameChannel == null) {
       debugPrint('❌ Send Failed: Channel is null');
       return;
    }
    try {
      await _gameChannel!.sendBroadcastMessage(
        payload: payload,
        event: 'game_event',
      );
      // debugPrint('Sent Broadcast: ${payload['type']}'); // Too verbose for drag?
    } catch (e) {
      debugPrint('❌ Send Broadcast Error: $e');
    }
  }

  bool isRealtimeConnected = false;

  void _subscribeToGame() {
    if (_sessionId == null) return;
    
    // Use a unique topic name for the room, avoiding 'public:' schema prefix for Broadcast-focused channel
    final channelName = 'room_$_sessionId';
    debugPrint('Subscribing to channel: $channelName');

    _gameChannel = _supabase.channel(channelName)
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'game_sessions',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: _sessionId!),
        callback: (payload) {
          debugPrint('Realtime Update Received!');
          _loadFromMap(payload.newRecord);
          notifyListeners();
        },
      )
      .onBroadcast(
        event: 'game_event', 
        callback: (payload) {
           debugPrint('Broadcast Received: $payload');
           if (payload['payload'] != null && payload['payload'] is Map) {
              _gameEventController.add(payload['payload']);
           } else {
              _gameEventController.add(payload);
           }
        }
      )
      .subscribe((status, error) {
         debugPrint('Subscription Status: $status');
         if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('✅ Connected to Realtime Channel');
            isRealtimeConnected = true;
            notifyListeners();
         } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.timedOut) {
            isRealtimeConnected = false;
            notifyListeners();
         }
         if (error != null) debugPrint('Subscription Error: $error');
      });
  }

  Future<void> updateTileOwnership(int index, String owner) async {
    _tileOwnership[index] = owner;
    notifyListeners();
    await _syncGameState();
  }

  Future<void> updateTurn(String nextTurn) async {
    currentTurn = nextTurn;
    turnCount++; // Increment Tick
    notifyListeners();
    await _syncGameState();
  }

  Future<void> startInteraction(int index, String type, String player, {String? q, String? A, String? B, List<String>? suggestions}) async {
    // Randomly select specific mini game if generic 'mini' requested
    String finalType = type;
    if (type == 'mini') {
       finalType = _nextMiniGameType();
    }

    interactionState = {
      'index': index,
      'step': 'answering',
      'type': finalType,
      'player': player,
      'question': q,
      'optionA': A,
      'optionB': B,
      'truthOptions': suggestions, // Sync Answer Suggestions for Truth Game
      'answer': null,
    };
    
    // Initialize Multiplayer Mini-Game State
    if (type.startsWith('mini')) {
       interactionState!['activePlayer'] = player; // The Initiator starts
       interactionState!['round'] = 1;
       interactionState!['scores'] = {'A': 0, 'B': 0};
    } else if (type == 'mini') {
       interactionState!['rolls'] = {'A': null, 'B': null};
    }

    // Inject System Message: The Question
    if (q != null && q.isNotEmpty) {
       messages.add({
         'sender': 'SYSTEM_Q',
         'text': q,
         'timestamp': DateTime.now().toIso8601String(),
         'player': player, // Who is being asked
         'type': type,
       });
    }

    notifyListeners();
    await _syncGameState();
  }


  Future<void> togglePause() async {
    if (gameStatus == 'paused') {
      gameStatus = 'playing';
    } else {
      gameStatus = 'paused';
    }
    notifyListeners();
    await _syncGameState();
  }

  // FORCE SYNC: Uploads questions/options to Supabase explicitly
  Future<void> uploadInitialQuestions() async {
    // This is called by Host after fetching questions to ensure Guest can see them
    await _syncGameState();
  }

  Future<void> setGameStatus(String status) async {
    gameStatus = status;
    notifyListeners();
    await _syncGameState();
  }

  // Track who is watching ad
  Map<String, bool> adWatchStatus = {'A': false, 'B': false};

  Future<void> updateAdStatus(bool watching) async {
    adWatchStatus[myRole] = watching;
    notifyListeners();
    await _syncGameState();
  }

  Future<void> startAdBreak() async {
    gameStatus = 'paused_ad';
    adWatchStatus = {'A': true, 'B': true};
    notifyListeners();
    await _syncGameState();
  }


  Future<void> cancelInteraction() async {
    interactionState = null;
    notifyListeners();
    await _syncGameState();
  }

  Future<void> startMiniGame(int index) async {
    // Check if Tile is Locked (LOCKED_A, LOCKED_B, or generic LOCKED)
    final owner = _tileOwnership[index];
    if (!owner.startsWith('LOCKED') && owner != 'X') {
      return; 
    }

    interactionState = {
      'index': index,
      'step': 'playing', // 'answering' -> 'playing' for mini game
      'type': 'mini',
      'player': myRole, // Who started it (The Aggressor/Linker)
      'activePlayer': myRole, // Round 1 starts with Aggressor
      'round': 1, 
      'scores': {'A': 0, 'B': 0},
    };
    notifyListeners();
    await _syncGameState();
  }


  
  // Challenge Mechanic
  Map<String, int> challengeCounts = {'A': 2, 'B': 2};

  Future<void> startChallenge(int index) async {
    // Check Challenge Count
    if ((challengeCounts[myRole] ?? 0) <= 0) {
      return; // UI should have blocked this, but safety check
    }

    interactionState = {
      'index': index,
      'step': 'playing',
      'type': 'challenge', // Special type for Challenge
      'subType': _nextMiniGameType(), // Round-robin mini-game selection
      'player': myRole, // Aggressor
      'activePlayer': myRole,
      'round': 1,
      'scores': {'A': 0, 'B': 0},
    };
    notifyListeners();
    await _syncGameState();
  }

  Future<void> resolveChallenge(String winner) async {
    if (interactionState == null) return;
    
    final int index = interactionState!['index'];
    final String aggressor = interactionState!['player'];
    final String defender = (aggressor == 'A') ? 'B' : 'A';
    
    // Decrement Aggressor's Challenge Count regardless of outcome
    int count = challengeCounts[aggressor] ?? 0;
    if (count > 0) challengeCounts[aggressor] = count - 1;

    if (winner == aggressor) {
       // SUCCESS: Take Tile
       _tileOwnership[index] = aggressor;
       
       // Reward Aggressor (Attack Bonus)
       if (myRole == aggressor) {
          addPoints(g: 10);
          addHistory("earn", 10, "Successful Challenge", price: "Challenge");
       }
       
       // System Msg
       addSystemMessage("Challenge SUCCESS! Tile Stolen!");

    } else {
       // FAILURE: Defender keeps tile (or Draw keeps it)
       // Reward Defender (Defense Bonus)
       // Only if it wasn't a Draw? Let's say Draw = Defender wins/keeps.
       // "Winner takes/keeps tile".
       
       if (myRole == defender) {
          addPoints(g: 5);
          addHistory("earn", 5, "Successful Defense", price: "Challenge");
       }

       addSystemMessage("Challenge FAILED! Tile Defended!");
    }
    
    // Turn Consumption: Turn ALWAYS passes to the other player
    currentTurn = (currentTurn == 'A') ? 'B' : 'A'; // Simple switch
    turnCount++; // ✅ Increment so locked-cell cooldown can expire

    interactionState = null;
    notifyListeners();
    await _syncGameState();
  }

  // Helper to check if a tile belongs to a completed line
  bool isTileInCompletedLine(int index) {
      // Check Rows
      int row = index ~/ 5;
      if ([0,1,2,3,4].every((c) {
          int idx = row * 5 + c;
          return _tileOwnership[idx] == _tileOwnership[index]; // Same owner as target
      })) return true;

      // Check Cols
      int col = index % 5;
      if ([0,1,2,3,4].every((r) {
          int idx = r * 5 + col;
          return _tileOwnership[idx] == _tileOwnership[index];
      })) return true;

      // Check Diagonals
      if ([0,6,12,18,24].contains(index)) {
         if ([0,6,12,18,24].every((i) => _tileOwnership[i] == _tileOwnership[index])) return true;
      }
      if ([4,8,12,16,20].contains(index)) {
         if ([4,8,12,16,20].every((i) => _tileOwnership[i] == _tileOwnership[index])) return true;
      }

      return false;
  }


  Future<void> submitAnswer(String answer) async {
    if (interactionState != null) {
      interactionState!['answer'] = answer;
      interactionState!['step'] = 'reviewing'; // Move to review step
      debugPrint('[Quiz] submitAnswer: answer="$answer", step=reviewing, type=${interactionState!["type"]}');
    
    // Inject System Message: The Answer
    messages.add({
      'sender': 'SYSTEM_A',
      'text': answer,
      'timestamp': DateTime.now().toIso8601String(),
      'player': interactionState!['player'], // Who answered
    });

    notifyListeners();
    await _syncGameState();
  }

  // --- Reporting ---
  Future<void> reportContent(String qId, String reason, {String? details}) async {
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id; 

      await _supabase.from('reports').insert({
        'q_id': qId,
        'reporter_id': userId,
        'reason': reason,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint("Content Reported: $qId - $reason");
    } catch (e) {
      debugPrint("Error reporting content: $e");
    }
  }
}

    Future<void> resolveInteraction(bool approved, {String? winnerOverride}) async {
    if (interactionState == null) {
       print("Warning: resolveInteraction called but interactionState is null. Ignoring.");
       return;
    }
    final index = interactionState!['index'] as int;
    final aggressor = interactionState!['player'] as String;
    final type = interactionState?['type'] as String?;
    
    // Determine who gets the tile (Aggressor by default, or specific Winner)
    final winner = winnerOverride ?? aggressor;

    if (approved) {
       _tileOwnership[index] = winner;
       // Award GP (+1) 
       if (winner == myRole) {
          addPoints(g: 1);
       }
       
       // Log "Mini [Nickname] WIN!" message
       if (type == 'mini') {
          final winnerName = (winner == 'A') ? (hostNickname ?? 'Host') : (guestNickname ?? 'Guest');
          final winText = "$winnerName WIN!";
          
          messages.add({
             'sender': 'SYSTEM_Q', 
             'text': winText,
             'timestamp': DateTime.now().toIso8601String(),
             'type': 'mini_game_win', 
          });
       }

       // Switch Turn? 
       // If A attacked and Won -> Turn stays A? Or passes?
       // Standard Rule: Turn Passes after Action.
       currentTurn = aggressor == 'A' ? 'B' : 'A';
       turnCount++; // ✅ Increment so locked-cell cooldown can expire
    } else {
       // Failed/Rejected
       // Lock the tile for the AGGRESSOR (or whoever was answering)
       _tileOwnership[index] = 'LOCKED_$aggressor'; 
       
       // Record Lock Time (Turn Count)
       lockedTurns[index.toString()] = turnCount;
       
       currentTurn = aggressor == 'A' ? 'B' : 'A';
       turnCount++; // ✅ Increment so locked-cell cooldown can expire
    }
    interactionState = null;
    notifyListeners();
    await _syncGameState();
  }

  Future<void> submitMiniGameScore(int score) async {
    if (interactionState == null) return;
    
    // Update Score
    final Map<String, dynamic> scores = Map<String, dynamic>.from(interactionState!['scores'] ?? {});
    scores[myRole] = score;
    interactionState!['scores'] = scores;

    final int round = interactionState!['round'] ?? 1;
    
    // Wait for BOTH scores to be submitted? 
    // Usually "Score Attack" means each player plays their round.
    // Round 1: A attacks, B defends. Score A recorded.
    // Round 2: B attacks, A defends. Score B recorded.
    // So distinct events.
    
    if (round == 1) {
      // Proceed to Round 2
      interactionState!['round'] = 2;
      interactionState!['activePlayer'] = (myRole == 'A' ? 'B' : 'A');
      notifyListeners();
      await _syncGameState();
    } else {
      // Round 2 Finished
      // Determine Winner
      final scoreA = scores['A'] as int? ?? 0;
      final scoreB = scores['B'] as int? ?? 0;
    
      String? winner;
      if (scoreA > scoreB) winner = 'A';
      else if (scoreB > scoreA) winner = 'B';
      // else Draw
    
      // Defer Resolution: Set step to 'finished' so clients can show Result Screen
      interactionState!['step'] = 'finished';
      interactionState!['winner'] = winner; 
      notifyListeners();
      await _syncGameState();
    }
  }

  Future<void> closeMiniGame() async {
    if (interactionState == null) return;
    final winner = interactionState!['winner'] as String?;
    
    // Route to Challenge Logic
    if (interactionState!['type'] == 'challenge') {
       await resolveChallenge(winner ?? 'DRAW');
       return;
    }

    if (winner != null) {
        await resolveInteraction(true, winnerOverride: winner);
    } else {
        await resolveInteraction(false); // Draw
    }
  }
  Future<void> endGame() async {
    gameStatus = 'finished';
    notifyListeners();
    await _syncGameState();
  }
  
  Future<void> updateGameQuestions(List<String> qs) async {}
  Future<void> updatePoints({int g = 0}) async {
     addPoints(g: g);
  }
  
  Future<void> chargeVpSecurely(int amount) async {
    try {
      // Securely increment on server
      final res = await _supabase.rpc('charge_vp', params: {'amount': amount});
      
      // Update local state with server response (new total) if returned, or just increment
      if (res != null) {
        vp = res as int;
      } else {
        vp += amount;
      }
      saveHostInfoToPrefs();
      notifyListeners();
      debugPrint("Charged $amount VP. New Balance: $vp");
    } catch (e) {
      debugPrint("Error charging VP: $e");
      // Fallback? Or throw? For now just log.
      throw e;
    }
  }

  /// Refresh VP balance from Supabase profiles table.
  /// Used after Edge Function grants VP server-side.
  Future<void> refreshVp() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final data = await _supabase
          .from('profiles')
          .select('vp')
          .eq('id', user.id)
          .single();
      if (data != null && data['vp'] != null) {
        vp = data['vp'] as int;
        saveHostInfoToPrefs();
        notifyListeners();
        debugPrint('VP refreshed from server: $vp');
      }
    } catch (e) {
      debugPrint('Error refreshing VP: $e');
    }
  }

  void addPoints({int g = 0}) {
    gp += g;
    saveHostInfoToPrefs(); // Persist changes
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String type = 'chat', Map<String, dynamic>? extra}) async {
    final newMessage = {
      'sender': myRole,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      if (extra != null) 'extra': extra,
    };
    messages.add(newMessage);
    notifyListeners();
    await _syncGameState();
  }

  Future<void> addSystemMessage(String text) async {
    final newMessage = {
      'sender': 'SYSTEM',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'system',
    };
    messages.add(newMessage);
    notifyListeners();
    await _syncGameState(); // Sync to all players
  }

  // --- Realtime Sync Helper ---
  Future<void> _syncGameState() async {
    if (_sessionId == null) return;
    
    // Construct the JSON blob
    final gameState = {
      'tileOwnership': _tileOwnership,
      'currentTurn': currentTurn,
      'interactionState': interactionState,
      'messages': messages,
      'questions': questions,
      'options': options, // Sync full options data
      'hostNickname': hostNickname,
      'guestNickname': guestNickname,
      'adWatchStatus': adWatchStatus, // Sync Ad Status
      // Persist Targeting for Rematch
      'relationMain': relationMain,
      'relationSub': relationSub,
      'intimacyLevel': intimacyLevel,
      'guestGender': guestGender,
      'challengeCounts': challengeCounts,
      'turnCount': turnCount,
      'lockedTurns': lockedTurns,
      'adFree': adFree || permanentAdFree,
      // Preview state for opponent sync
      'previewCellIndex': previewCellIndex.value,
      'previewLabel': previewLabel,
      'previewRole': myRole,
    };

    try {
      await _supabase.from('game_sessions').update({
        'status': gameStatus,
        'game_state': gameState,
      }).eq('id', _sessionId!);
    } catch (e) {
      debugPrint("Error syncing game state: $e");
    }
  }

  Future<void> submitGuestRating(double rating) async {
    if (_sessionId == null) return;
    try {
      // Fetch current game state to append/merge
      // Or just patch the specific field if structure allows.
      // Since game_state is a JSONB, we can update it.
      // Ideally we'd sync the whole state, but let's assume valid state.
      
      final currentState = await _supabase.from('game_sessions').select('game_state').eq('id', _sessionId!).single();
      final Map<String, dynamic> state = currentState['game_state'] ?? {};
      
      state['guestRating'] = rating;
      
      await _supabase.from('game_sessions').update({
        'game_state': state
      }).eq('id', _sessionId!);
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting rating: $e");
    }
  }

  void _loadFromMap(Map<String, dynamic> data) {
    if (data['status'] != null) gameStatus = data['status'];
    
    if (data['game_state'] != null) {
      final state = data['game_state'];
      debugPrint('[Synced State] Received State: $state'); // Debug Log
      
      if (state['tileOwnership'] != null) {
        _tileOwnership = List<String>.from(state['tileOwnership']);
      }
      if (state['currentTurn'] != null) {
        currentTurn = state['currentTurn'];
      }
      if (state['interactionState'] != null) {
        interactionState = state['interactionState'];
      } else {
        interactionState = null;
      }
      if (state['messages'] != null) {
        messages = List<Map<String, dynamic>>.from(state['messages']);
      }
      
      if (state['challengeCounts'] != null) {
         challengeCounts = Map<String, int>.from(state['challengeCounts']);
      }
      if (state['turnCount'] != null) {
         turnCount = state['turnCount'];
      }
      if (state['lockedTurns'] != null) {
         lockedTurns = Map<String, int>.from(state['lockedTurns']);
      }
      
      // Also sync questions if present and local is empty (e.g. guest join)
      // Or always update if we trust the server state is latest? 
      // Merging strategy: If local is empty, take server.
      if (questions.isEmpty && state['questions'] != null) {
         questions = List<String>.from(state['questions']);
      }
      
      // SYNC OPTIONS for Guest visibility
      if (options.isEmpty && state['options'] != null) {
         options = List<Map<String, dynamic>>.from(state['options']);
      } else if (state['options'] != null && (options.length < (state['options'] as List).length)) {
         // If server has MORE options (e.g. filled fallback), update local
         options = List<Map<String, dynamic>>.from(state['options']);
      }

      // Sync Nicknames
      if (state['hostNickname'] != null) hostNickname = state['hostNickname'];
      if (state['guestNickname'] != null) {
          guestNickname = state['guestNickname'];
          
          // Check for Guest Join (Chat Notification) - HOST ONLY
          // If I am Host ('A') and guest wasn't here before but is here now
          if (myRole == 'A' && (_lastKnownGuestNickname == null || _lastKnownGuestNickname!.isEmpty) && 
              guestNickname != null && guestNickname!.isNotEmpty) {
              
               final joinMsg = "${guestNickname} ${AppLocalizations.get('user_joined')}";
               // Add System Message (Async - Fire & Forget or Await?)
               // Since we are in the middle of processing a sync, triggering another sync is okay but we should notifyListeners first?
               // addSystemMessage calls notifyListeners and _syncGameState.
               // We should make sure we don't block this function.
               Future.microtask(() => addSystemMessage(joinMsg));
          }
          _lastKnownGuestNickname = guestNickname;
      }
      
      // Sync Ad Watch Status
      if (state['adWatchStatus'] != null) {
         adWatchStatus = Map<String, bool>.from(state['adWatchStatus']);
         // Check for Auto-Resume on Client Side too (for Guest to know active)
         // Actually Host drives state change to 'playing', so Guest just waits for status update.
      }

      // Sync Ad-Free State (Host → Guest)
      if (state['adFree'] == true && myRole == 'B') {
        adFree = true;
      }

      // Sync Targeting Info (for Rematch/Review)
      if (state['relationMain'] != null) relationMain = state['relationMain'];
      if (state['relationSub'] != null) relationSub = state['relationSub'];
      if (state['intimacyLevel'] != null) intimacyLevel = state['intimacyLevel'];
      if (state['guestGender'] != null) guestGender = state['guestGender'];

    // Sync Preview State from opponent
    if (state['previewRole'] != null && state['previewRole'] != myRole) {
      final pIdx = state['previewCellIndex'];
      remotePreviewCellIndex.value = (pIdx is int) ? pIdx : null;
      remotePreviewLabel = state['previewLabel'] as String?;
    }
      
      // Check for Trust Score Update (Host Side)
      if (state['guestRating'] != null && !hostRatingProcessed) {
         double rating = (state['guestRating'] as num).toDouble();
         _processTrustScoreUpdate(rating);
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> calculateEndGameResults() {
     int linesA = 0;
     int linesB = 0;
     int cellsA = 0;
     int cellsB = 0;
     
     // 1. Calculate Owned Cells (EP)
     // Rule: +1 EP per owned cell
     for (String owner in _tileOwnership) {
        if (owner == 'A') cellsA++;
        if (owner == 'B') cellsB++;
     }

     // 2. Calculate Lines (AP Logic)
     // Rows
     for (int row = 0; row < 5; row++) {
        if ([0,1,2,3,4].every((c) => _tileOwnership[row * 5 + c] == 'A')) linesA++;
        if ([0,1,2,3,4].every((c) => _tileOwnership[row * 5 + c] == 'B')) linesB++;
     }
     // Cols
     for (int col = 0; col < 5; col++) {
        if ([0,1,2,3,4].every((r) => _tileOwnership[r * 5 + col] == 'A')) linesA++;
        if ([0,1,2,3,4].every((r) => _tileOwnership[r * 5 + col] == 'B')) linesB++;
     }
     // Diagonals
     if ([0,6,12,18,24].every((i) => _tileOwnership[i] == 'A')) linesA++;
     if ([0,6,12,18,24].every((i) => _tileOwnership[i] == 'B')) linesB++;
     
     if ([4,8,12,16,20].every((i) => _tileOwnership[i] == 'A')) linesA++;
     if ([4,8,12,16,20].every((i) => _tileOwnership[i] == 'B')) linesB++;

     // 3. AP Rule: 1st(+20), 2nd(+40), 3rd(+60)
     // Function to calc AP based on line count
     int calcAp(int lines) {
       int score = 0;
       if (lines >= 1) score += 20;
       if (lines >= 2) score += 40;
       if (lines >= 3) score += 60;
       return score;
     }
     int lineGpA = calcAp(linesA);
     int lineGpB = calcAp(linesB);

     // 4. Determine Winner & GP Logic (Victory GP)
     // Rules: 
     // - Scenario 1 (1 Line): 20 GP
     // - Scenario 2 (2 Lines): Double (40 GP)
     // - Scenario 3 (Draw/Split): 50% (10 GP each)
     // - Scenario 5 (Board Full/No Win): 0 GP
     
     String winner = 'DRAW';
     int winGpA = 0;
     int winGpB = 0;

     if (linesA > linesB) {
        winner = 'A';
        int base = 20;
        if (linesA >= 2) base *= 2; // Double
        if (linesA >= 3) base = 60; // Triple (20*3)
        winGpA = base;
        winGpB = 0;
     } else if (linesB > linesA) {
        winner = 'B';
        int base = 20;
        if (linesB >= 2) base *= 2;
        if (linesB >= 3) base = 60;
        winGpB = base;
        winGpA = 0;
     } else {
        // Draw (linesA == linesB)
        if (linesA > 0) {
           winGpA = 10;
           winGpB = 10;
        } else {
           winGpA = 0;
           winGpB = 0;
        }
     }

     // 5. Cell GP: +1 per cell
     int cellGpA = cellsA;
     int cellGpB = cellsB;

     // 6. Total GP = cell GP + line GP + win GP
     int totalGpA = cellGpA + lineGpA + winGpA;
     int totalGpB = cellGpB + lineGpB + winGpB;

     // 7. Return Results (Pure Calculation)
     return {
        'linesA': linesA,
        'linesB': linesB,
        'gpA': totalGpA,
        'gpB': totalGpB,
        'vpA': winGpA,    // Victory Points
        'vpB': winGpB,
        'epA': cellGpA,   // Exploration Points (cells owned)
        'epB': cellGpB,
        'apA': lineGpA,   // Achievement Points (lines completed)
        'apB': lineGpB,
        'winner': winner
     };
  }

  void applyEndGameRewards() {
     final results = calculateEndGameResults();
     final gpA = results['gpA'] as int;
     final gpB = results['gpB'] as int;

     if (myRole == 'A') {
         addPoints(g: gpA);
     } else if (myRole == 'B') {
         addPoints(g: gpB); 
     }
  }

  
  void addHistory(String type, int amount, String desc, {String? price, String? roomName}) {
     final now = DateTime.now();
     final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
     pointHistory.insert(0, { // Insert at beginning for newest first
       'date': dateStr,
       'type': type, 
       'amount': amount, 
       'desc': desc,
       'price': price,
       'roomName': roomName
     });
     notifyListeners();
  }

  bool useVpForAdRemoval() {
    if (permanentAdFree) return true; // Already permanent
    if (vp >= 25) {
      vp -= 25;
      adFree = true;
      saveHostInfoToPrefs();
      addHistory("use", 25, "Ad Removal", price: "25 VP");
      notifyListeners();
      _syncGameState(); // Sync to guest
      return true;
    }
    return false;
  }

  /// Use 8,000 VP for permanent ad removal
  bool useVpForPermanentAdRemoval() {
    if (permanentAdFree) return true; // Already permanent
    if (vp >= 8000) {
      vp -= 8000;
      permanentAdFree = true;
      adFree = true;
      saveHostInfoToPrefs();
      addHistory("use", 8000, "Permanent Ad Removal", price: "8,000 VP");
      notifyListeners();
      _syncGameState(); // Sync to guest
      return true;
    }
    return false;
  }

  /// Award 5 VP from watching a rewarded ad. Returns true if successful.
  bool rewardVpFromAd() {
    // Reset daily counter if date changed
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    if (lastRewardedAdDate != today) {
      dailyRewardedAdCount = 0;
      lastRewardedAdDate = today;
    }
    
    // Check daily limit (max 10)
    if (dailyRewardedAdCount >= 10) {
      return false;
    }
    
    // Award 5 VP
    vp += 5;
    dailyRewardedAdCount++;
    saveHostInfoToPrefs();
    addHistory("earn", 5, "Rewarded Ad", price: "Ad Watch");
    notifyListeners();
    return true;
  }

  /// Get remaining rewarded ad views today
  int get remainingRewardedAds {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastRewardedAdDate != today) return 10;
    return (10 - dailyRewardedAdCount).clamp(0, 10);
  }



  void reset() {
    _sessionId = null;
    gameStatus = 'waiting';
    interactionState = null;
    _tileOwnership = List.filled(25, '');
    questions = [];
    messages = [];
    currentTurn = 'A';
    myRole = '';
    hostRatingProcessed = false; // Reset flag
    challengeCounts = {'A': 2, 'B': 2};
    turnCount = 1;
    lockedTurns = {};
    // do not reset Host info or points
    notifyListeners();
  }
  int _calculateLines(String role) {
    int count = 0;
    // Rows
    for (int i = 0; i < 5; i++) {
      bool rowWin = true;
      for (int k=0; k<5; k++) {
         if (_tileOwnership[(i*5)+k] != role) rowWin = false;
      }
      if (rowWin) count++;
    }
    return count;
  }
  
  // Serialization Helpers
  Map<String, dynamic> toJson() {
    return {
      'hostNickname': hostNickname,
      'guestNickname': guestNickname,
      'gp': gp,
      'vp': vp,
      // Add simplified serialization if needed by UI
    };
  }
  
  Map<String, dynamic> fullToJson() {
     return {
       'sessionId': _sessionId,
       'hostId': hostId,
       'guestId': guestId,
       'questions': questions,
       'tileOwnership': _tileOwnership,
       'currentTurn': currentTurn,
       'gameStatus': gameStatus,
       'adWatchStatus': adWatchStatus,
     };
  }
  
  void loadFromJson(Map<String, dynamic> json) {
     _sessionId = json['sessionId'];
     if (json['questions'] != null) questions = List<String>.from(json['questions']);
     if (json['tileOwnership'] != null) _tileOwnership = List<String>.from(json['tileOwnership']);
     currentTurn = json['currentTurn'] ?? 'A';
     gameStatus = json['gameStatus'] ?? 'waiting';
     if (json['adWatchStatus'] != null) {
        adWatchStatus = Map<String, bool>.from(json['adWatchStatus']);
     }
     notifyListeners();
  }

  bool hostRatingProcessed = false;

  void _processTrustScoreUpdate(double newRating) async {
    if (hostId == null) return;
    
    // 1. Calculate New Weighted Average
    double currentScore = hostTrustScore; 
    int currentCount = hostTrustCount;
    
    double newScore = ((currentScore * currentCount) + newRating) / (currentCount + 1);
    int newCount = currentCount + 1;
    
    // 2. Update Local State
    hostTrustScore = newScore;
    hostTrustCount = newCount;
    hostRatingProcessed = true; // Mark as processed for this session
    
    // 3. Persist Local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hostTrustScore', hostTrustScore);
    await prefs.setInt('hostTrustCount', hostTrustCount);
    
    // 4. Update Remote (Profiles Table)
    // Note: Assuming RLS allows Host to update OWN profile
    try {
      await _supabase.from('profiles').update({
        'trust_score': hostTrustScore,
        'trust_count': hostTrustCount,
      }).eq('id', hostId!);
      
      debugPrint("✅ Trust Score Updated: $newScore ($newCount ratings)");
      notifyListeners();
      
      // Optional: Show Toast/Snack via Service or Listener? 
      // Since this is Model, we just notify.
    } catch (e) {
      debugPrint("Error updating Trust Score: $e");
    }
  }

  @override
  void dispose() {
    _gameChannel?.unsubscribe();
    remoteHoverIndex.dispose();
    previewCellIndex.dispose();
    remotePreviewCellIndex.dispose();
    super.dispose();
  }

  // --- Realtime Cursor Broadcast ---
  double opponentCursorX = 0.0;
  double opponentCursorY = 0.0;
  bool opponentCursorVisible = false;
  Timer? _cursorThrottle;
  Timer? _cursorFadeTimer;

  /// Broadcast cursor position (normalized 0-1 coordinates) with 100ms throttle
  void broadcastCursorPosition(double normalizedX, double normalizedY) {
    if (_cursorThrottle?.isActive == true) return;
    
    _cursorThrottle = Timer(const Duration(milliseconds: 100), () {});
    
    sendGameEvent({
      'type': 'cursor',
      'x': normalizedX,
      'y': normalizedY,
      'role': myRole,
    });
  }

  /// Broadcast cursor lifted (finger removed)
  void broadcastCursorLifted() {
    sendGameEvent({
      'type': 'cursor_lift',
      'role': myRole,
    });
  }

  /// Handle incoming cursor events (called from gameEvents stream listener)
  void handleCursorEvent(Map<String, dynamic> payload) {
    final eventType = payload['type'];
    final role = payload['role'];
    
    // Only process opponent's cursor
    if (role == myRole) return;
    
    if (eventType == 'cursor') {
      opponentCursorX = (payload['x'] as num?)?.toDouble() ?? 0.0;
      opponentCursorY = (payload['y'] as num?)?.toDouble() ?? 0.0;
      opponentCursorVisible = true;
      
      // Auto-hide after 2 seconds of no updates
      _cursorFadeTimer?.cancel();
      _cursorFadeTimer = Timer(const Duration(seconds: 2), () {
        opponentCursorVisible = false;
        notifyListeners();
      });
      
      notifyListeners();
    } else if (eventType == 'cursor_lift') {
      opponentCursorVisible = false;
      notifyListeners();
    }
  }

  void broadcastHover(int? index) {}

  /// Broadcast cell preview selection (1st tap)
  Future<void> broadcastPreview(int? index, String? label) async {
    debugPrint('[Preview] Broadcasting: index=$index, label=$label, role=$myRole');
    previewCellIndex.value = index;
    previewLabel = label;
    // Primary: DB sync (reliable via Postgres Realtime)
    notifyListeners();
    await _syncGameState();
    // Secondary: also send broadcast for faster delivery
    try {
      await sendGameEvent({
        'type': 'preview',
        'index': index,
        'label': label,
        'role': myRole,
      });
    } catch (e) {
      debugPrint('[Preview] Broadcast send error (non-critical): $e');
    }
  }

  /// Handle incoming preview events from opponent
  void handlePreviewEvent(Map<String, dynamic> payload) {
    final role = payload['role'];
    debugPrint('[Preview] Received event: role=$role, myRole=$myRole, index=${payload['index']}, label=${payload['label']}');
    if (role == myRole) return; // ignore own events
    
    final index = payload['index'] as int?;
    final label = payload['label'] as String?;
    remotePreviewCellIndex.value = index;
    remotePreviewLabel = label;
    debugPrint('[Preview] Remote preview set: index=$index, label=$label');
    notifyListeners();
  }

  /// Clear preview state (e.g. on turn change or interaction start)
  Future<void> clearPreview() async {
    debugPrint('[Preview] Clearing preview');
    previewCellIndex.value = null;
    previewLabel = null;
    // Primary: DB sync
    notifyListeners();
    await _syncGameState();
    // Secondary: broadcast for faster delivery
    try {
      await sendGameEvent({
        'type': 'preview',
        'index': null,
        'label': null,
        'role': myRole,
      });
    } catch (e) {
      debugPrint('[Preview] Clear broadcast error (non-critical): $e');
    }
  }
  Future<void> reportContent(String qId, String reason, {String? details}) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('reports').insert({
        'q_id': qId,
        'reporter_id': user?.id, // Can be null if guest, but RLS might require auth. 
        // If guest reporting is allowed, table should allow public insert or anon.
        'reason': reason,
        'details': details,
      });
      debugPrint("✅ Report submitted for $qId: $reason");
    } catch (e) {
      debugPrint("❌ Error sending report: $e");
    }
  }

  void _setupRealtimeHover() {
    /*
    if (_sessionId == null) return;
    
    _gameChannel = _supabase.channel('game_$_sessionId');
         RealtimeListenTypes.broadcast,
         ChannelFilter(event: 'hover'),
         (payload, [ref]) {
             final data = payload;
             final senderRole = data['role'];
             final index = data['index'];
             
             if (senderRole != myRole) {
                remoteHoverIndex.value = index;
             }
         }
      ).subscribe();
  */
  }
  

  // --- Missing Methods Implementation ---
  


}
