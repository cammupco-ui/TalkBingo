1. 업데이트된 요구사항
1.1 다국어 지원
✅ 기기 언어 자동 감지 (한국어/영어)
✅ 모든 가이드 텍스트 다국어 처리
✅ 동적 언어 전환 지원
1.2 독립적인 가이드 시스템
✅ 기존 앱 로직에 영향 없음
✅ "다시 보지 않기" 옵션
✅ 설정에서 가이드 재활성화 가능
✅ 가이드 스킵 시에도 앱 정상 작동
2. 다국어 시스템 구현
2.1 기존 다국어 시스템 확인
현재 코드:

// lib/utils/localization.dart
class AppLocalizations {
  final Locale locale;
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // 기존 문자열들
    },
    'ko': {
      // 기존 문자열들
    },
  };
  
  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }
}
2.2 가이드용 다국어 추가
확장:

// lib/utils/localization.dart 에 추가
class GuideStrings {
  // Home Onboarding
  static const String homeOnboarding1Title = 'home_onboarding_1_title';
  static const String homeOnboarding1Desc = 'home_onboarding_1_desc';
  static const String homeOnboarding2Title = 'home_onboarding_2_title';
  static const String homeOnboarding2Desc = 'home_onboarding_2_desc';
  static const String homeOnboarding3Title = 'home_onboarding_3_title';
  static const String homeOnboarding3Desc = 'home_onboarding_3_desc';
  
  // Setup Onboarding
  static const String setupOnboarding1Title = 'setup_onboarding_1_title';
  static const String setupOnboarding1Desc = 'setup_onboarding_1_desc';
  
  // Game Hints
  static const String hintFirstTile = 'hint_first_tile';
  static const String hintBingoAchieved = 'hint_bingo_achieved';
  static const String hintWaiting = 'hint_waiting';
  
  // Onboarding Controls
  static const String skip = 'onboarding_skip';
  static const String next = 'onboarding_next';
  static const String done = 'onboarding_done';
  static const String dontShowAgain = 'onboarding_dont_show_again';
  static const String gotIt = 'onboarding_got_it';
  static const String stepOf = 'onboarding_step_of'; // "1 / 5"
}

// _localizedStrings에 추가
static Map<String, Map<String, String>> _localizedStrings = {
  'en': {
    // 기존 문자열들...
    
    // Home Onboarding
    'home_onboarding_1_title': 'Create a Game',
    'home_onboarding_1_desc': 'Start a new TalkBingo game with friends',
    'home_onboarding_2_title': 'Join a Game',
    'home_onboarding_2_desc': 'Enter a room code to join an existing game',
    'home_onboarding_3_title': 'Settings',
    'home_onboarding_3_desc': 'Customize your profile and preferences',
    
    // Setup Onboarding
    'setup_onboarding_1_title': 'Choose Relationship',
    'setup_onboarding_1_desc': 'Select your relationship with the other player',
    
    // Hints
    'hint_first_tile': 'Tap a tile to start a question',
    'hint_bingo_achieved': 'Bingo! Play a mini-game for bonus points',
    'hint_waiting': 'Please wait for the other player to respond',
    
    // Controls
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_done': 'Done',
    'onboarding_dont_show_again': "Don't show again",
    'onboarding_got_it': 'Got it',
    'onboarding_step_of': '%1 / %2', // %1 = current, %2 = total
  },
  'ko': {
    // 기존 문자열들...
    
    // Home Onboarding
    'home_onboarding_1_title': '게임 만들기',
    'home_onboarding_1_desc': '친구와 함께 새로운 TalkBingo 게임을 시작하세요',
    'home_onboarding_2_title': '게임 참가',
    'home_onboarding_2_desc': '방 코드를 입력하여 게임에 참여하세요',
    'home_onboarding_3_title': '설정',
    'home_onboarding_3_desc': '프로필과 환경설정을 변경하세요',
    
    // Setup Onboarding
    'setup_onboarding_1_title': '관계 선택',
    'setup_onboarding_1_desc': '상대방과의 관계를 선택하세요',
    
    // Hints
    'hint_first_tile': '타일을 탭하여 질문을 시작하세요',
    'hint_bingo_achieved': '빙고! 미니게임으로 보너스 점수를 획득하세요',
    'hint_waiting': '상대방이 응답할 때까지 기다려주세요',
    
    // Controls
    'onboarding_skip': '건너뛰기',
    'onboarding_next': '다음',
    'onboarding_done': '완료',
    'onboarding_dont_show_again': '다시 보지 않기',
    'onboarding_got_it': '확인',
    'onboarding_step_of': '%1 / %2',
  },
};

// 헬퍼 메서드 추가
String translateWithParams(String key, List<String> params) {
  String text = translate(key);
  for (int i = 0; i < params.length; i++) {
    text = text.replaceAll('%${i + 1}', params[i]);
  }
  return text;
}
3. 독립적인 온보딩 시스템
3.1 온보딩 상태 관리 (완전 독립)
// lib/utils/onboarding_manager.dart
class OnboardingManager {
  // SharedPreferences Keys
  static const String _keyFirstLaunch = 'onboarding_first_launch';
  static const String _keyHomeOnboardingShown = 'onboarding_home_shown';
  static const String _keySetupOnboardingShown = 'onboarding_setup_shown';
  static const String _keyGameOnboardingShown = 'onboarding_game_shown';
  static const String _keyNeverShowAgain = 'onboarding_never_show_again';
  
  // Check if user opted out of all onboarding
  static Future<bool> hasOptedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNeverShowAgain) ?? false;
  }
  
  // Check if specific onboarding should show
  static Future<bool> shouldShowHomeOnboarding() async {
    if (await hasOptedOut()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyHomeOnboardingShown) ?? false);
  }
  
  static Future<bool> shouldShowSetupOnboarding() async {
    if (await hasOptedOut()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keySetupOnboardingShown) ?? false);
  }
  
  static Future<bool> shouldShowGameOnboarding() async {
    if (await hasOptedOut()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyGameOnboardingShown) ?? false);
  }
  
  // Mark specific onboarding as shown
  static Future<void> markHomeOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHomeOnboardingShown, true);
  }
  
  static Future<void> markSetupOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupOnboardingShown, true);
  }
  
  static Future<void> markGameOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGameOnboardingShown, true);
  }
  
  // User opts out of all onboarding
  static Future<void> setNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNeverShowAgain, true);
  }
  
  // Reset onboarding (for Settings menu)
  static Future<void> resetAllOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNeverShowAgain, false);
    await prefs.setBool(_keyHomeOnboardingShown, false);
    await prefs.setBool(_keySetupOnboardingShown, false);
    await prefs.setBool(_keyGameOnboardingShown, false);
  }
  
  // Show onboarding with options
  static void showHomeOnboarding(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final targets = [
      TargetFocus(
        identify: "create_game",
        keyTarget: _createGameKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => OnboardingCard(
              title: l10n.translate(GuideStrings.homeOnboarding1Title),
              description: l10n.translate(GuideStrings.homeOnboarding1Desc),
              currentStep: 1,
              totalSteps: 3,
              onSkip: () {
                controller.skip();
                _showSkipDialog(context);
              },
              onNext: () => controller.next(),
            ),
          ),
        ],
      ),
      // ... more targets
    ];
    
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () async {
        await markHomeOnboardingShown();
        _showCompletionDialog(context);
      },
      onSkip: () => _showSkipDialog(context),
    ).show(context: context);
  }
  
  // Skip confirmation dialog
  static Future<void> _showSkipDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('onboarding_skip_title')),
        content: Text(l10n.translate('onboarding_skip_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Just mark as shown, don't set never show again
              markHomeOnboardingShown();
            },
            child: Text(l10n.translate(GuideStrings.skip)),
          ),
          TextButton(
            onPressed: () async {
              await setNeverShowAgain();
              Navigator.pop(context);
            },
            child: Text(l10n.translate(GuideStrings.dontShowAgain)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Completion dialog
  static Future<void> _showCompletionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉'),
        content: Text(l10n.translate('onboarding_complete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate(GuideStrings.gotIt)),
          ),
        ],
      ),
    );
  }
}
3.2 안전한 통합 (기존 로직 보호)
// home_screen.dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // ✅ 기존 로직 먼저 실행
    _initializeScreen();
    
    // ✅ 온보딩은 마지막에, 독립적으로
    _checkAndShowOnboarding();
  }
  
  void _initializeScreen() {
    // 기존 초기화 로직
    // ...
  }
  
  // 완전히 독립적인 온보딩 체크
  void _checkAndShowOnboarding() {
    // addPostFrameCallback으로 화면 빌드 후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // ✅ 온보딩 실패해도 앱은 정상 작동
        if (await OnboardingManager.shouldShowHomeOnboarding()) {
          // mounted 체크로 안전성 확보
          if (mounted) {
            OnboardingManager.showHomeOnboarding(context);
          }
        }
      } catch (e) {
        // ✅ 에러 발생해도 앱은 정상 작동
        debugPrint('Onboarding error: $e');
        // 필요시 에러 로깅
      }
    });
  }
  
  // 기존 메서드들은 그대로 유지
  void _navigateToCreateGame() {
    // 기존 로직...
  }
}
4. 설정에서 가이드 재활성화
4.1 설정 화면 추가
// settings_screen.dart 에 추가
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return ListView(
      children: [
        // 기존 설정들...
        
        // 가이드 설정 섹션
        _buildSectionHeader(l10n.translate('settings_guide_section')),
        
        ListTile(
          leading: Icon(Icons.help_outline),
          title: Text(l10n.translate('settings_reset_onboarding')),
          subtitle: Text(l10n.translate('settings_reset_onboarding_desc')),
          onTap: () => _resetOnboarding(),
        ),
        
        ListTile(
          leading: Icon(Icons.lightbulb_outline),
          title: Text(l10n.translate('settings_show_hints')),
          subtitle: Text(l10n.translate('settings_show_hints_desc')),
          trailing: Switch(
            value: _showHints,
            onChanged: (value) => _toggleHints(value),
          ),
        ),
      ],
    );
  }
  
  Future<void> _resetOnboarding() async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('settings_reset_onboarding_confirm')),
        content: Text(l10n.translate('settings_reset_onboarding_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await OnboardingManager.resetAllOnboarding();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('settings_reset_onboarding_success')),
          backgroundColor: AppColors.hostPrimary,
        ),
      );
    }
  }
}
4.2 다국어 추가
// localization.dart 에 추가
static Map<String, Map<String, String>> _localizedStrings = {
  'en': {
    // ... 기존 문자열들
    
    // Settings - Guide
    'settings_guide_section': 'User Guide',
    'settings_reset_onboarding': 'Reset Tutorial',
    'settings_reset_onboarding_desc': 'Show the tutorial again',
    'settings_reset_onboarding_confirm': 'Reset Tutorial?',
    'settings_reset_onboarding_confirm_desc': 'The tutorial will be shown again when you return to the home screen.',
    'settings_reset_onboarding_success': 'Tutorial has been reset',
    'settings_show_hints': 'Show Hints',
    'settings_show_hints_desc': 'Display helpful hints during gameplay',
    
    // Onboarding dialogs
    'onboarding_skip_title': 'Skip Tutorial?',
    'onboarding_skip_message': 'You can view the tutorial again from Settings.',
    'onboarding_complete_message': 'Tutorial complete! You can now start playing.',
  },
  'ko': {
    // ... 기존 문자열들
    
    // Settings - Guide
    'settings_guide_section': '사용자 가이드',
    'settings_reset_onboarding': '튜토리얼 초기화',
    'settings_reset_onboarding_desc': '튜토리얼을 다시 표시합니다',
    'settings_reset_onboarding_confirm': '튜토리얼을 초기화할까요?',
    'settings_reset_onboarding_confirm_desc': '홈 화면으로 돌아가면 튜토리얼이 다시 표시됩니다.',
    'settings_reset_onboarding_success': '튜토리얼이 초기화되었습니다',
    'settings_show_hints': '힌트 표시',
    'settings_show_hints_desc': '게임 중 유용한 힌트를 표시합니다',
    
    // Onboarding dialogs
    'onboarding_skip_title': '튜토리얼을 건너뛸까요?',
    'onboarding_skip_message': '설정에서 언제든지 튜토리얼을 다시 볼 수 있습니다.',
    'onboarding_complete_message': '튜토리얼 완료! 이제 게임을 시작할 수 있습니다.',
  },
};
5. 온보딩 카드 다국어 적용
// lib/widgets/onboarding_card.dart
class OnboardingCard extends StatelessWidget {
  final String title;
  final String description;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final bool isLast;
  
  const OnboardingCard({
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    this.onSkip,
    this.onNext,
    this.isLast = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = GameSession();
    final primaryColor = session.myRole == 'A'
        ? AppColors.hostPrimary
        : AppColors.guestPrimary;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicator
          Text(
            l10n.translateWithParams(
              GuideStrings.stepOf,
              [currentStep.toString(), totalSteps.toString()],
            ),
            style: GoogleFonts.alexandria(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 12),
          
          // Title
          Text(
            title,
            style: GoogleFonts.doHyeon(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: GoogleFonts.doHyeon(
              fontSize: 14,
              color: Colors.white90,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    l10n.translate(GuideStrings.skip),
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              Spacer(),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                ),
                child: Text(
                  isLast 
                    ? l10n.translate(GuideStrings.done)
                    : l10n.translate(GuideStrings.next),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
6. 기기 언어 자동 감지
// main.dart 또는 app initialization
class TalkBingoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 기기 언어 자동 감지
      localeResolutionCallback: (locale, supportedLocales) {
        // 기기 언어가 지원 언어 중 하나인지 확인
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        // 기본값: 한국어
        return supportedLocales.first;
      },
      supportedLocales: [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
      ],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ... 나머지 설정
    );
  }
}
7. 안전성 체크리스트
7.1 기존 로직 보호
✅ 독립성 확인:

// ❌ 나쁜 예: 온보딩이 앱 초기화를 방해
void initState() {
  if (shouldShowOnboarding()) {
    showOnboarding();
  }
  _initializeApp(); // 온보딩 후에만 실행됨!
}

// ✅ 좋은 예: 온보딩과 앱 초기화 분리
void initState() {
  _initializeApp(); // 항상 먼저 실행
  _checkOnboarding(); // 독립적으로 실행
}

void _checkOnboarding() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      if (await OnboardingManager.shouldShowHomeOnboarding()) {
        if (mounted) {
          OnboardingManager.showHomeOnboarding(context);
        }
      }
    } catch (e) {
      // 에러 무시, 앱은 계속 실행
      debugPrint('Onboarding error: $e');
    }
  });
}
7.2 에러 핸들링
// 온보딩 매니저 내부에 try-catch
static Future<bool> shouldShowHomeOnboarding() async {
  try {
    if (await hasOptedOut()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyHomeOnboardingShown) ?? false);
  } catch (e) {
    // SharedPreferences 에러 등 발생 시 기본값 반환
    debugPrint('Onboarding check error: $e');
    return false; // 에러 시 온보딩 표시 안 함
  }
}
8. 구현 로드맵 (업데이트)
Week 1: 다국어 + 기본 온보딩
단계	작업	파일
1.1	가이드용 다국어 추가	localization.dart
1.2	OnboardingManager (독립)	onboarding_manager.dart
1.3	OnboardingCard (다국어)	onboarding_card.dart
1.4	홈 화면 온보딩 통합	home_screen.dart
Week 2: 설정 + 재활성화
단계	작업	파일
2.1	설정 메뉴 추가	settings_screen.dart
2.2	온보딩 리셋 기능	onboarding_manager.dart
2.3	힌트 on/off 토글	hint_manager.dart
Week 3: 게임 온보딩
단계	작업	파일
3.1	게임 설정 온보딩	game_setup_screen.dart
3.2	게임 플레이 온보딩	game_screen.dart
Week 4: 테스트 + 최적화
단계	작업	내용
4.1	언어 전환 테스트	한/영 전환 확인
4.2	독립성 테스트	온보딩 실패 시 앱 정상 작동 확인
4.3	사용자 테스트	피드백 수집
9. 코드 변경 요약 (업데이트)
파일	작업	변경 라인 수
pubspec.yaml	추가	+2줄
lib/utils/localization.dart	수정	+150줄 (다국어)
lib/utils/onboarding_manager.dart	생성	+200줄 (독립 시스템)
lib/widgets/onboarding_card.dart	생성	+100줄 (다국어 지원)
home_screen.dart	수정	+25줄 (안전한 통합)
settings_screen.dart	수정	+60줄 (리셋 기능)
game_setup_screen.dart	수정	+20줄 (온보딩)
game_screen.dart	수정	+30줄 (온보딩)
10. 최종 보장사항
10.1 독립성 보장
온보딩 시스템 실패 시나리오:
❌ SharedPreferences 에러
❌ 네트워크 문제
❌ 메모리 부족
❌ 사용자 강제 종료

→ ✅ 앱은 정상 작동
→ ✅ 기능 손실 없음
→ ✅ 다음 실행 시 재시도
10.2 사용자 제어
사용자 옵션:
✅ 건너뛰기 (이번만)
✅ 다시 보지 않기 (영구)
✅ 설정에서 재활성화
✅ 각 화면별 독립 제어
10.3 다국어 완전 지원
지원 언어:
✅ 한국어 (기본)
✅ 영어
✅ 기기 언어 자동 감지
✅ 수동 전환 가능
To-dos (6)
 다국어 확장: localization.dart에 가이드용 문자열 150줄 추가 (한/영)
 독립 매니저: OnboardingManager 구현, try-catch로 에러 처리, 기존 로직 보호
 스킵/다시보지않기: 스킵 다이얼로그 + setNeverShowAgain() 기능
 설정 통합: settings_screen.dart에 온보딩 리셋 메뉴 추가
 안전한 통합: addPostFrameCallback + mounted 체크로 기존 화면에 영향 없이 적용
 기기 언어 감지: localeResolutionCallback로 한/영 자동 선택