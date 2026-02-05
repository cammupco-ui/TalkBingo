import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/models/game_session.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'new_game': 'NEW\nGAME',
      'resume_game': 'RESUME\nGAME',
      'find_players': 'FIND\nPLAYERS',
      'welcome_back': 'Welcome Back,',
      'vp_label': 'VP',
      'manage_points': 'Manage Points',
      'account_email': 'Account Email',
      'nickname': 'Nickname',
      'gender': 'Gender',
      'birth_date': 'Birth Date',
      'sns': 'SNS / Instagram',
      'address': 'Address',
      'phone_number': 'Phone Number',
      'allow_region': 'Allow Region Access',
      'agree_retention': 'Agree to Personal Information Retention',
      'retention_sub': 'Your data will be stored locally and securely.',
      'save_changes': 'Save Changes',
      'sign_out': 'Sign Out',
      'cancel': 'Cancel',
      'male': 'Male',
      'female': 'Female',
      'app_settings': 'App Settings',
      'profile_settings': 'Profile Settings',
      'language': 'Language',
      'invite_code_title': 'INVITE CODE',
      'next': 'NEXT',
      'error_invalid_code': 'Please enter a valid 6-character code.',
      'error_prefix': 'Error: ',
      'join': 'JOIN',
      'bingo_history': 'BINGO HISTORY',
      'view_all': 'VIEW ALL',
      'start_game': 'Start Game',
      'relationship': 'Relationship',
      'intimacy_level': 'Intimacy Level',
      'guest_settings': 'Guest Settings',
      'select_relation': 'Select specific relationship',
      'preparing_game': 'Preparing Game...',
      'gen_codename': 'Generating CodeName...',
      'sync_info': 'Syncing Host & Guest Info...',
      'load_questions': 'Loading Questions...',
      // Relations
      'Friend': 'Friend',
      'Family': 'Family',
      'Lover': 'Lover',
      // Intimacy Titles
      'level_1_title': 'First Meeting',
      'level_2_title': 'Getting to Know',
      'level_3_title': 'Close Friends',
      'level_4_title': 'Consulting',
      'level_5_title': 'Deep Trust',
      'settings_saved': 'Settings Saved!',
      'start_new_game': 'Start New Game?',
      'start_new_warning': 'Current progress will be lost.',
      'start_new': 'Start New',
      'coming_soon': 'Coming Soon',
      'service_unavailable': 'This service is not yet available.',
      'sign_up_google': 'SIGN UP GOOGLE',
      'enter_invite_placeholder': 'Enter Invite Code',
      'enter_invite_code': 'INVITE CODE',
      'already_account': 'Already have an account? ',
      'log_in': 'Log in',
      'continue_google': 'Continue with Google',
      'quick_secure_login': 'Quick & Secure Login without Passwords',
      'verification_expired': 'Verification link expired. Please send email again.',
      'verification_timeout': 'Verification timed out. Try refreshing or use the manual link.',
      'invalid_link': 'Invalid link: No code found',
      'error_occurred': 'Error occurred',
      'verify': 'Verify',
      'enter_link_title': 'Enter Verification Link',
      'menu_resume': 'Resume',
      'menu_pause': 'Pause',
      'menu_restart': 'Restart Game',
      'menu_end': 'End Game',
      'menu_save': 'Save Game',
      'menu_load': 'Load Game',
      'trust_score_title': 'Trust Score',
      'trust_score_desc': 'Build trust with mannerly conversation.',
      'close': 'Close',
      'user_joined': 'joined the game.',
      'support': 'Support',
      'send_feedback': 'Send Feedback',
      'support_info': 'Customer Support & Info',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'licenses': 'Open Source Licenses',
      'version_info': 'Version',
      'contact_us': 'Contact Us',
      'delete_account': 'Delete Account',
      'delete_account_title': 'Delete Account',
      'delete_account_warning': 'This action cannot be undone. All your data will be permanently deleted.',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'password_mismatch': 'Passwords do not match',
      'weak_password': 'Password should be at least 6 characters',
      'check_email_verification': 'Please check your email for a verification link.',
      'send_reset_link': 'Send Reset Link',
      'reset_link_sent': 'Password reset link sent to your email.',
      'sign_up_email': 'Sign Up with Email',
      'login_email': 'Log In with Email',
      'enter_email': 'Enter your email',
      'enter_password': 'Enter your password',
      'or_divider': 'OR',
      'account_exists': 'Account already exists.\nRedirecting to Login...',
      'board': 'Board',
      'guide_bingo': 'How to Play',
      'guide_points': 'Points Guide',
      'board_title': 'TalkBingo Board',
      'my_inquiries': 'My Inquiries',
      'public_board': 'Public / Notices',
      'write_btn': 'Write',
      'no_inquiries': 'No inquiries yet.\nFeel free to ask or suggest anything!',
      'public_coming_soon': 'Public board & Notices coming soon!',
      'write_title': 'Write Inquiry',
      'post_btn': 'Post',
      'category_label': 'Category',
      'title_label': 'Title',
      'title_hint': 'Summarize your inquiry',
      'content_label': 'Content',
      'content_hint': 'Describe your issue or suggestion...',
      'private_post': 'Private Post',
      'private_post_desc': 'Only you and admins can see this.',
      'device_info_notice': 'Device info and app version will be automatically attached to help us resolve issues faster.',
      'inquiry_submitted': 'Inquiry submitted successfully!',
      'inquiry_details': 'Inquiry Details',
      'waiting_response': 'Waiting for response...',
      'admin_response': 'Admin Response',
      'talkbingo_team': 'TalkBingo Team',
      'status_submitted': 'SUBMITTED',
      'status_progress': 'IN PROGRESS',
      'status_resolved': 'RESOLVED',
      // Board Categories
      'cat_general': 'General',
      'cat_bug': 'Bug Report',
      'cat_feature': 'Feature Suggestion',
      'cat_payment': 'Payment/Points',
      'cat_account': 'Account/Login',
      'cat_etc': 'Etc',
      'manage_account': 'Manage Account',
      'sign_in_another': 'Sign In Another Account',
      'exit_talkbingo': 'Exit TalkBingo (Delete Data)',
      'reset_exit': 'Exit Guest Mode',
      
      // Guides
      'guide_read_confirm': 'I have read and understood the above.',
      'guide_confirm_btn': 'Confirm',
      
      'guide_bingo_content': '''
1. **Talk & Lock**: Talk about the topic on the cell to lock it.
2. **5x5 Grid**: Complete 5 cells in a row, column, or diagonal to make a BINGO.
3. **Steal (Challenge)**: You can challenge an opponent's locked cell to steal it! (Max 2 attempts per game).
   - *Line Immunity*: Cells that are part of a completed Bingo line cannot be stolen.
   - *Cooldown*: A newly locked cell is protected for 3 turns.
4. **Win**: The player with the most Bingo lines wins!
''',

      'guide_points_content': '''
* **VP (Victory Points)**: 
  - Earned by winning games.
  - Used for Global Rankings.

* **AP (Action Points)**: 
  - Earned by talking and locking cells.
  - Used to use Items or Challenge opponents.

* **EP (Engagement Points)**: 
  - Earned by receiving 'Likes' or 'Manner Scores' from partners.
  - High EP unlocks special avatars.
''',
      'guide_terms_content': '''
**Terms of Service**

1. **Acceptance**: By using TalkBingo, you agree to these terms.
2. **User Conduct**: No abusive behavior or harassment.
3. **Data**: We store minimal data for gameplay.
4. **Liability**: We are not responsible for user disputes.
(This is a summarized placeholder. Full terms will be updated.)
''',
      'guide_privacy_content': '''
**Privacy Policy**

1. **Information Collection**: We collect email, nickname, and game data.
2. **Usage**: Data is used for gameplay, auth, and analytics.
3. **Sharing**: We do not share data with 3rd parties without consent.
4. **Deletion**: You can delete your account at any time in Settings.
(This is a summarized placeholder. Full policy will be updated.)
''',
    },
    'ko': {
      'new_game': '새 게임',
      'resume_game': '이어하기',
      'find_players': '친구 찾기',
      'welcome_back': '환영합니다,',
      'vp_label': 'VP',
      'manage_points': '포인트 관리',
      'account_email': '계정 이메일',
      'nickname': '닉네임',
      'gender': '성별',
      'birth_date': '생년월일',
      'sns': 'SNS / 인스타그램',
      'address': '주소 (시/도)',
      'phone_number': '휴대폰 번호',
      'allow_region': '지역 정보 접근 허용',
      'agree_retention': '개인정보 보관 동의',
      'retention_sub': '데이터는 안전하게 로컬에 저장됩니다.',
      'save_changes': '변경사항 저장',
      'sign_out': '로그아웃',
      'cancel': '취소',
      'male': '남성',
      'female': '여성',
      'app_settings': '앱 설정',
      'profile_settings': '프로필 설정',
      'language': '언어',
      'invite_code_title': '초대 코드',
      'next': '다음',
      'error_invalid_code': '유효한 6자리 코드를 입력해주세요.',
      'error_prefix': '오류: ',
      'join': '참여',
      'bingo_history': '빙고 기록',
      'view_all': '전체 보기',
      'start_game': '게임 시작',
      'relationship': '관계',
      'intimacy_level': '친밀도',
      'guest_settings': '게스트 설정',
      'select_relation': '세부 관계 선택',
      'preparing_game': '게임 준비 중...',
      'gen_codename': '코드네임 생성 중...',
      'sync_info': '호스트 & 게스트 동기화...',
      'load_questions': '질문지 불러오는 중...',
      // Relations
      'Friend': '친구',
      'Family': '가족',
      'Lover': '연인',
      // Intimacy Titles (Simplified for mapping, real data is in list)
      'level_1_title': '첫 만남 (어색한 사이)',
      'level_2_title': '알아가는 단계',
      'level_3_title': '친한 사이',
      'level_4_title': '고민 상담 가능',
      'level_5_title': '깊은 신뢰',
      'settings_saved': '설정이 저장되었습니다!',
      'start_new_game': '새 게임을 시작하시겠습니까?',
      'start_new_warning': '현재 진행 중인 게임 기록은 저장되지 않습니다.',
      'start_new': '새로 시작',
      'coming_soon': '준비 중',
      'service_unavailable': '아직 이용할 수 없는 서비스입니다.',
      'sign_up_google': 'Google로 시작하기',
      'enter_invite_placeholder': '초대받은 코드를 입력하세요',
      'enter_invite_code': '초대 코드 입력하기',
      'already_account': '이미 계정이 있으신가요? ',
      'log_in': '로그인',
      'continue_google': 'Google로 계속하기',
      'quick_secure_login': '비밀번호 없이 빠르고 안전하게 로그인하세요',
      'verification_expired': '인증 링크가 만료되었습니다. 다시 시도해주세요.',
      'verification_timeout': '인증 시간이 초과되었습니다. 다시 시도해주세요.',
      'invalid_link': '유효하지 않은 링크입니다.',
      'error_occurred': '오류가 발생했습니다.',
      'verify': '인증하기',
      'enter_link_title': '인증 링크 입력',
      'menu_resume': '재개',
      'menu_pause': '일시정지',
      'menu_restart': '게임 재시작',
      'menu_end': '게임 종료',
      'menu_save': '게임 저장',
      'menu_load': '게임 불러오기',
      'trust_score_title': '신뢰 점수',
      'trust_score_desc': '매너있는 대화로 신뢰를 얻으세요',
      'close': '닫기',
      'user_joined': '님이 입장하셨습니다.',
      'support': '지원',
      'send_feedback': '의견 보내기',
      'support_info': '고객 지원 및 정보',
      'terms_of_service': '서비스 이용약관',
      'privacy_policy': '개인정보 처리방침',
      'licenses': '오픈소스 라이선스',
      'version_info': '버전 정보',
      'contact_us': '문의하기',
      'delete_account': '회원 탈퇴',
      'delete_account_title': '회원 탈퇴',
      'delete_account_warning': '탈퇴 시 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 계속하시겠습니까?',
      'email': '이메일',
      'password': '비밀번호',
      'confirm_password': '비밀번호 확인',
      'forgot_password': '비밀번호를 잊으셨나요?',
      'password_mismatch': '비밀번호가 일치하지 않습니다.',
      'weak_password': '비밀번호는 6자 이상이어야 합니다.',
      'check_email_verification': '이메일로 전송된 인증 링크를 확인해주세요.',
      'send_reset_link': '재설정 링크 전송',
      'reset_link_sent': '비밀번호 재설정 링크가 이메일로 전송되었습니다.',
      'sign_up_email': '이메일로 회원가입',
      'login_email': '이메일 로그인',
      'enter_email': '이메일을 입력하세요',
      'enter_password': '비밀번호를 입력하세요',
      'or_divider': '또는',
      'account_exists': '이미 가입된 계정입니다.\n로그인 페이지로 이동합니다.',
      'board': '게시판',
      'guide_bingo': '빙고 플레이 방법',
      'guide_points': '포인트 사용 방법',
      'board_title': '톡빙고 게시판',
      'my_inquiries': '내 문의 내역',
      'public_board': '공지사항 / 전체글',
      'write_btn': '글쓰기',
      'no_inquiries': '아직 문의 내역이 없습니다.\n궁금한 점이나 건의사항을 남겨주세요!',
      'public_coming_soon': '공지사항 및 전체 게시판은 준비 중입니다!',
      'write_title': '문의 작성',
      'post_btn': '등록',
      'category_label': '카테고리',
      'title_label': '제목',
      'title_hint': '문의 내용을 요약해주세요',
      'content_label': '내용',
      'content_hint': '문의하실 내용이나 제안을 자세히 적어주세요...',
      'private_post': '비공개 글',
      'private_post_desc': '나와 관리자만 볼 수 있습니다.',
      'device_info_notice': '빠른 문제 해결을 위해 기기 정보와 앱 버전이 자동으로 첨부됩니다.',
      'inquiry_submitted': '문의가 정상적으로 등록되었습니다!',
      'inquiry_details': '문의 상세',
      'waiting_response': '답변 대기 중...',
      'admin_response': '톡빙고 답변',
      'talkbingo_team': 'TalkBingo 운영팀',
      'status_submitted': '접수됨',
      'status_progress': '처리중',
      'status_resolved': '답변완료',
      // Board Categories
      'cat_general': '일반 문의',
      'cat_bug': '버그 신고',
      'cat_feature': '기능 제안',
      'cat_payment': '결제/포인트',
      'cat_account': '계정/로그인',
      'cat_etc': '기타',
      'manage_account': '계정 관리',
      'sign_in_another': '다른 계정으로 로그인',
      'exit_talkbingo': 'TalkBingo 나가기 (데이터 삭제)',
      'reset_exit': '게스트 모드 종료',

      // Guides
      'guide_read_confirm': '위 내용을 모두 확인했습니다.',
      'guide_confirm_btn': '확인',
      
      'guide_bingo_content': '''
1. **대화 후 잠금 (Talk & Lock)**: 셀의 주제에 대해 대화하고 셀을 터치해 잠그세요.
2. **빙고 완성**: 가로, 세로, 대각선으로 5개의 셀을 잠그면 빙고!
3. **스틸 (챌린지)**: 상대방이 잠근 셀을 뺏어올 수 있습니다! (게임당 최대 2회)
   - *라인 면역*: 이미 완성된 빙고 라인에 속한 셀은 뺏을 수 없습니다.
   - *쿨타임*: 방금 잠긴 셀은 3턴 동안 보호됩니다.
4. **승리**: 더 많은 빙고 라인을 완성한 사람이 승리합니다!
''',

      'guide_points_content': '''
* **VP (승리 포인트)**: 
  - 빙고 게임 승리 시 획득합니다.
  - 글로벌 랭킹 산정에 사용됩니다.

* **AP (액션 포인트)**: 
  - 대화를 하거나 셀을 잠글 때 획득합니다.
  - 아이템 사용이나 '스틸(챌린지)'을 할 때 소모됩니다.

* **EP (참여/매너 포인트)**: 
  - 상대방에게 '좋아요'나 '매너 점수'를 받으면 획득합니다.
  - 높은 EP를 모으면 특별한 아바타를 해금할 수 있습니다.
''',
      'guide_terms_content': '''
**서비스 이용약관**

1. **동의**: TalkBingo를 사용함으로써 본 약관에 동의합니다.
2. **사용자 행동**: 욕설 및 비방 등 부적절한 행위를 금지합니다.
3. **데이터**: 게임 진행을 위한 최소한의 데이터를 저장합니다.
4. **책임**: 사용자 간의 분쟁에 대해 당사는 책임을 지지 않습니다.
(요약된 내용입니다. 추후 업데이트될 예정입니다.)
''',
      'guide_privacy_content': '''
**개인정보 처리방침**

1. **수집 항목**: 이메일, 닉네임, 게임 진행 데이터.
2. **사용 목적**: 게임 서비스 제공, 인증, 통계 분석.
3. **제3자 제공**: 동의 없이 데이터를 제3자에게 제공하지 않습니다.
4. **파기**: 회원 탈퇴 시 데이터를 즉시 파기합니다.
(요약된 내용입니다. 추후 업데이트될 예정입니다.)
''',
    },
  };
  static String get(String key) {
    final lang = GameSession().language; // 'en' or 'ko'
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  // Font Switcher
  static TextStyle getTextStyle({
    required TextStyle baseStyle, 
    FontWeight? fontWeight, 
    double? fontSize,
    Color? color,
  }) {
    final lang = GameSession().language;
    final size = fontSize ?? baseStyle.fontSize;
    final weight = fontWeight ?? baseStyle.fontWeight;
    final col = color ?? baseStyle.color;

    if (lang == 'ko') {
       // Korean Font
       // Use secondary font if needed, but primary is fine for consistency
       // Assuming 'EliceDigitalBaeum_Regular.ttf' is registered as 'EliceDigitalBaeum'
       return TextStyle(
         fontFamily: 'EliceDigitalBaeum', 
         fontSize: size,
         fontWeight: weight,
         color: col,
         height: baseStyle.height,
       );
    } else {
       // English Font (Alexandria)
       return GoogleFonts.alexandria(
         fontSize: size,
         fontWeight: weight,
         color: col,
         height: baseStyle.height,
       );
    }
  }
}
