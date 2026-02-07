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
      // Bingo Modal
      'bingo_title_final': 'BINGO! 🏆',
      'bingo_title': 'BINGO! 🎉',
      'bingo_opponent': 'OPPONENT BINGO!',
      'bingo_winner_final': 'Congratulations! 3-line Bingo!\nThe game is over.',
      'bingo_winner': ' line Bingo completed!',
      'bingo_loser_final': 'Unfortunately, ',
      'bingo_loser_final_suffix': ' completed 3 lines first.',
      'bingo_loser': 'Unfortunately, ',
      'bingo_loser_suffix': ' completed lines first.',
      'bingo_ad_hint_final': 'Points available after watching an ad',
      'bingo_ad_hint_round': 'Round starts after watching an ad',
      'bingo_continue': 'Continue Play',
      'bingo_end': 'End Game',
      'bingo_confirm': 'OK',
      // Ad-Free VP Modal
      'ad_free_title': 'Ad-Free Game',
      'ad_free_desc': 'Use 200 VP to remove ads for this game?',
      'ad_free_current_vp': 'Current VP: ',
      'ad_free_use': 'Use 200 VP',
      'ad_free_skip': 'Play with Ads',
      'ad_free_not_enough': 'Not enough VP (need 200)',
      
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
# Terms of Service

**(Last Updated: February 2026)**

Please read these Terms of Service ("Terms") carefully before using the TalkBingo application ("App", "Service"). By accessing or using TalkBingo, you agree to be bound by these Terms.

These Terms apply to all users of TalkBingo games, apps, websites, and related services (together, the "Services"). These Terms explain how CAMMUPCO ("Company", "we", "us", "our") provides and manages the Services.

---

## Table of Contents

1. Eligibility and Account
2. Description of Services
3. Virtual Currency and In-App Purchases
4. User Conduct
5. Intellectual Property
6. User-Generated Content
7. Advertising
8. Disclaimers and Limitation of Liability
9. Termination
10. Changes to These Terms
11. Contact Us

---

## 1. Eligibility and Account

You must be at least **14 years old** to use TalkBingo. If you are under 18, you must have parental or guardian consent.

**Account Types:**

- **Guest Account**: You may use the App without registration. Guest data is stored locally and on our servers but may be lost if you clear app data or uninstall.
- **Registered Account**: You can create an account using email or Google Sign-In. This ensures your gameplay data, points, and history are securely stored and recoverable.

You are responsible for maintaining the confidentiality of your account credentials.

---

## 2. Description of Services

TalkBingo is a **relationship-based real-time conversational bingo game platform**. The Service includes:

- **5×5 Bingo Board**: Tiles contain conversation prompts (Balance and Truth questions) tailored to your relationship type and intimacy level.
- **Real-time Multiplayer**: Two players connect via invite codes and play in real-time with synchronized game states.
- **Chat & Voice**: In-game text chat and voice messaging between players.
- **Dynamic Content**: Questions adapt based on player gender, relationship, and intimacy for natural conversation.
- **Mini-Games**: Penalty kick and target shooter games for resolving locked tiles.

---

## 3. Virtual Currency and In-App Purchases

TalkBingo uses a virtual currency system:

- **VP (Victory Points)**: Earned through gameplay. Can be used to remove ads (200 VP per game) or exchanged for items.
- **AP (Action Points)**: Consumed when performing in-game actions such as challenges or item usage.
- **EP (Engagement Points)**: Earned by receiving positive ratings from other players.

**In-App Purchases:**

- You may purchase VP with real currency (e.g., 1,000 VP for ₩900 KRW).
- All purchases are final and non-refundable except as required by applicable law.
- Virtual currency has no real-world monetary value and cannot be transferred, traded, or redeemed for cash.
- Purchased VP may be subject to expiration as outlined in the App.

---

## 4. User Conduct

You agree NOT to:

- Use obscene, abusive, threatening, or harassing language in chat or voice messages.
- Attempt to exploit, hack, or reverse-engineer the App or its servers.
- Create multiple accounts for fraudulent purposes.
- Share inappropriate, illegal, or harmful content through the chat system.
- Manipulate game results, scores, or virtual currency through unauthorized means.

We reserve the right to suspend or terminate accounts that violate these rules without prior notice.

---

## 5. Intellectual Property

All content in TalkBingo — including but not limited to game design, questions, UI elements, logos, sounds, and code — is the exclusive property of CAMMUPCO and is protected by applicable intellectual property laws.

You may not copy, modify, distribute, or create derivative works from any part of the Service without our prior written consent.

---

## 6. User-Generated Content

Chat messages and voice recordings sent during gameplay are considered user-generated content. By using the chat features, you grant us a limited, non-exclusive license to process this content for the purpose of delivering the Service (e.g., real-time message delivery, moderation).

We do not claim ownership of your chat messages. Chat data is stored for the duration of the game session and may be deleted upon game completion.

---

## 7. Advertising

TalkBingo may display advertisements, including:

- **Banner Ads**: Displayed at the bottom of the game screen.
- **Interstitial Ads**: Displayed between game rounds.
- **Rewarded Ads**: Optional ads you can watch to earn points or unlock features.

You may remove ads for individual games by spending 200 VP. Ad preferences can be managed in your device settings.

---

## 8. Disclaimers and Limitation of Liability

The Service is provided "AS IS" without warranties of any kind. We are not liable for:

- Any disputes between players.
- Loss of data due to device failures or network issues.
- Temporary unavailability of the Service.
- Content or behavior of other users.

Our total liability shall not exceed the amount you paid to us in the 12 months preceding the claim.

---

## 9. Termination

You may delete your account at any time through the Settings page. Upon deletion:

- All personal data will be permanently removed from our servers.
- Virtual currency and game history will be irreversibly deleted.
- This action cannot be undone.

We may also terminate or suspend your access if you violate these Terms.

---

## 10. Changes to These Terms

We may update these Terms from time to time. Material changes will be notified through the App. Continued use of the Service after changes constitutes acceptance of the updated Terms.

---

## 11. Contact Us

If you have questions about these Terms, please contact us:

- **Email**: talkbingohelp@gmail.com
- **Website**: https://talkbingo.app
''',
      'guide_privacy_content': '''
# Privacy Policy

**(Last Updated: February 2026)**

Please read this Privacy Policy carefully to understand our policies and practices regarding your Personal Data and how we will treat it.

This Privacy Policy applies to TalkBingo games, apps, and related services (together, the "Services"). This Privacy Policy explains how CAMMUPCO ("Company", "we", "us", "our") collects, uses, secures, and discloses end-users\' ("you" or "your") personal information when you use our Services.

---

## Table of Contents

1. Information We Collect and How
2. Sources of Data
3. Purposes for Which We Use Your Data
4. Retention of Personal Data
5. Data Sharing and Third Parties
6. Cross-border Data Transfers
7. Age Limits
8. Your Rights and Options
9. Data Security
10. Changes to This Privacy Policy
11. Contact Us

---

## 1. Information We Collect and How

**Information You Provide:**

- **Account Information**: Email address, nickname, gender, date of birth (optional), profile photo (optional).
- **Communication Data**: Chat messages and voice recordings sent during gameplay.
- **Transaction Data**: In-app purchase history and virtual currency balance.

**Information Collected Automatically:**

- **Device Information**: Device type, operating system, browser type, unique device identifiers.
- **Usage Data**: Game sessions played, scores, gameplay patterns, features used.
- **Log Data**: IP address, access times, error logs.

---

## 2. Sources of Data

We collect data from the following sources:

- **Directly from you**: When you create an account, play games, or contact support.
- **Third-party sign-in**: Google Sign-In (email and profile information).
- **Automated tools**: Analytics and crash reporting services.
- **Game partners**: When you interact with other players during gameplay.

---

## 3. Purposes for Which We Use Your Data

We use your information for:

- **Service Delivery**: Providing gameplay, matchmaking, real-time synchronization, and chat features.
- **Personalization**: Adapting game questions based on your relationship settings, gender, and intimacy level.
- **Account Management**: Authentication, account recovery, and profile management.
- **Payments**: Processing in-app purchases and managing virtual currency.
- **Analytics**: Understanding usage patterns to improve the Service.
- **Safety**: Detecting fraud, abuse, and enforcing our Terms of Service.
- **Advertising**: Displaying relevant ads (subject to your preferences).

---

## 4. Retention of Personal Data

- **Active accounts**: Data is retained as long as your account is active.
- **Game session data**: Stored during active gameplay and for a limited period after game completion.
- **Chat messages**: Retained for the duration of the game session.
- **Deleted accounts**: All personal data is permanently deleted within 30 days of account deletion.
- **Anonymous/Guest accounts**: Data may be retained until you clear app data or request deletion.

---

## 5. Data Sharing and Third Parties

We do **not** sell your personal data. We may share data with:

- **Supabase**: Our backend infrastructure provider for authentication, database storage, and real-time features.
- **Google**: For authentication (Google Sign-In) and advertising (AdMob).
- **Analytics providers**: For crash reporting and usage analytics.
- **Legal authorities**: When required by law or legal process.

All third-party services are bound by their respective privacy policies and data protection agreements.

---

## 6. Cross-border Data Transfers

Your data may be transferred to and processed in countries outside your country of residence, including the United States and Republic of Korea. We ensure appropriate safeguards are in place to protect your data in accordance with applicable data protection laws.

---

## 7. Age Limits

TalkBingo is not intended for children under 14. We do not knowingly collect personal data from children under 14. If we discover such data has been collected, we will delete it promptly.

---

## 8. Your Rights and Options

Depending on your location, you may have the following rights:

- **Access**: Request a copy of your personal data.
- **Correction**: Request correction of inaccurate data.
- **Deletion**: Request deletion of your account and all associated data (available in Settings > Delete Account).
- **Data Portability**: Request your data in a portable format.
- **Opt-out**: Opt out of personalized advertising through your device settings.
- **Withdraw Consent**: Withdraw consent for data processing at any time.

**For EU/EEA residents (GDPR):** You have the right to lodge a complaint with your local data protection authority.

**For California residents (CCPA):** You have the right to know what personal information is collected and to request its deletion. We do not sell personal information.

**How to exercise your rights:** You can manage most data settings within the App (Settings page). For additional requests, contact us at the email below.

---

## 9. Data Security

We implement industry-standard security measures to protect your data:

- **Encryption**: Data in transit is encrypted using TLS/SSL.
- **Access Control**: Row-Level Security (RLS) policies ensure users can only access their own data.
- **Secure Payments**: Point transactions are processed through server-side functions to prevent tampering.
- **Authentication**: Secure token-based authentication through Supabase Auth.

While we strive to protect your data, no method of electronic transmission or storage is 100% secure.

---

## 10. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of material changes through the App. Your continued use of the Service after changes constitutes acceptance.

---

## 11. Contact Us

If you have questions about this Privacy Policy or wish to exercise your data rights:

- **Email**: talkbingohelp@gmail.com
- **Website**: https://talkbingo.app

You may also manage your privacy settings directly within the App under Settings.
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
      // Bingo Modal
      'bingo_title_final': 'BINGO! 🏆',
      'bingo_title': 'BINGO! 🎉',
      'bingo_opponent': '상대방 BINGO!',
      'bingo_winner_final': '축하합니다! 3줄 빙고 완성!\n게임이 종료됩니다.',
      'bingo_winner': '줄 빙고를 완성했습니다!',
      'bingo_loser_final': '아쉽게도 ',
      'bingo_loser_final_suffix': '님이 3줄을 먼저 완성하셨습니다.',
      'bingo_loser': '아쉽게도 ',
      'bingo_loser_suffix': '줄을 먼저 완성하셨습니다.',
      'bingo_ad_hint_final': '광고 시청 후 포인트 확인됩니다',
      'bingo_ad_hint_round': '라운드 시작입니다',
      'bingo_continue': '계속 플레이',
      'bingo_end': '게임 종료',
      'bingo_confirm': '확인',
      // Ad-Free VP Modal
      'ad_free_title': '광고 없는 게임',
      'ad_free_desc': '200 VP를 사용하여 이 게임의 광고를 제거하시겠습니까?',
      'ad_free_current_vp': '현재 VP: ',
      'ad_free_use': '200 VP 사용',
      'ad_free_skip': '광고 있는 게임',
      'ad_free_not_enough': 'VP가 부족합니다 (200 필요)',

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
# 서비스 이용약관

**(최종 수정일: 2026년 2월)**

TalkBingo 애플리케이션("앱", "서비스")을 사용하기 전에 본 서비스 이용약관("약관")을 주의 깊게 읽어주세요. TalkBingo에 접속하거나 사용함으로써 본 약관에 동의하게 됩니다.

본 약관은 TalkBingo의 게임, 앱, 웹사이트 및 관련 서비스(통칭 "서비스")의 모든 사용자에게 적용됩니다. 본 약관은 CAMMUPCO("회사", "당사", "우리")가 서비스를 제공하고 관리하는 방법을 설명합니다.

---

## 목차

1. 이용 자격 및 계정
2. 서비스 설명
3. 가상 화폐 및 인앱 구매
4. 사용자 행동 규칙
5. 지적 재산권
6. 사용자 생성 콘텐츠
7. 광고
8. 면책 조항 및 책임 제한
9. 해지 및 탈퇴
10. 약관 변경
11. 연락처

---

## 1. 이용 자격 및 계정

TalkBingo를 사용하려면 만 **14세 이상**이어야 합니다. 만 18세 미만인 경우 부모 또는 보호자의 동의가 필요합니다.

**계정 유형:**

- **게스트 계정**: 회원가입 없이 앱을 사용할 수 있습니다. 게스트 데이터는 기기와 서버에 저장되지만, 앱 데이터를 삭제하거나 앱을 제거하면 손실될 수 있습니다.
- **회원 계정**: 이메일 또는 Google 로그인으로 계정을 생성할 수 있습니다. 이를 통해 게임 데이터, 포인트, 기록이 안전하게 저장되고 복구 가능합니다.

계정 자격 증명의 기밀성을 유지할 책임은 사용자에게 있습니다.

---

## 2. 서비스 설명

TalkBingo는 **관계 기반 실시간 대화형 빙고 게임 플랫폼**입니다. 서비스에는 다음이 포함됩니다:

- **5×5 빙고 보드**: 관계 유형과 친밀도에 맞춤화된 대화 주제(밸런스 및 진실 질문)가 포함된 타일.
- **실시간 멀티플레이어**: 초대 코드를 통해 두 플레이어가 연결되어 동기화된 게임 상태로 실시간 플레이.
- **채팅 및 음성**: 게임 중 텍스트 채팅 및 음성 메시지.
- **동적 콘텐츠**: 플레이어의 성별, 관계, 친밀도에 따라 자연스러운 대화를 위해 질문이 자동 변환.
- **미니게임**: 잠긴 타일을 해결하기 위한 승부차기 및 타겟 슈터 게임.

---

## 3. 가상 화폐 및 인앱 구매

TalkBingo는 가상 화폐 시스템을 사용합니다:

- **VP (Victory Points)**: 게임 플레이를 통해 획득. 광고 제거(게임당 200 VP) 또는 아이템 교환에 사용 가능.
- **AP (Action Points)**: 챌린지나 아이템 사용 등 게임 내 행동 수행 시 소모.
- **EP (Engagement Points)**: 다른 플레이어로부터 긍정적인 평가를 받으면 획득.

**인앱 구매:**

- 실제 화폐로 VP를 구매할 수 있습니다 (예: 1,000 VP = ₩900원).
- 관련 법률에서 요구하는 경우를 제외하고 모든 구매는 최종적이며 환불이 불가능합니다.
- 가상 화폐는 실제 금전적 가치가 없으며, 양도, 거래 또는 현금으로 환전할 수 없습니다.
- 구매한 VP는 앱에서 명시한 바에 따라 만료될 수 있습니다.

---

## 4. 사용자 행동 규칙

다음 행위를 해서는 안 됩니다:

- 채팅이나 음성 메시지에서 음란하거나 모욕적, 위협적, 또는 괴롭히는 언어를 사용하는 행위.
- 앱이나 서버를 악용, 해킹, 또는 역분석하려는 시도.
- 부정한 목적으로 여러 계정을 생성하는 행위.
- 채팅 시스템을 통해 부적절하거나 불법적, 유해한 콘텐츠를 공유하는 행위.
- 게임 결과, 점수 또는 가상 화폐를 무단 수단으로 조작하는 행위.

당사는 사전 통지 없이 이러한 규칙을 위반하는 계정을 일시 중지하거나 종료할 권리를 보유합니다.

---

## 5. 지적 재산권

TalkBingo의 모든 콘텐츠 — 게임 디자인, 질문, UI 요소, 로고, 사운드, 코드를 포함하되 이에 국한되지 않는 — 는 CAMMUPCO의 독점 자산이며 관련 지적 재산권법에 의해 보호됩니다.

당사의 사전 서면 동의 없이 서비스의 어떤 부분도 복사, 수정, 배포 또는 파생 저작물을 만들 수 없습니다.

---

## 6. 사용자 생성 콘텐츠

게임 중 전송된 채팅 메시지 및 음성 녹음은 사용자 생성 콘텐츠로 간주됩니다. 채팅 기능을 사용함으로써, 서비스 제공 목적(예: 실시간 메시지 전달, 검토)으로 이 콘텐츠를 처리할 수 있는 제한적인 비독점 라이선스를 당사에 부여합니다.

당사는 사용자의 채팅 메시지에 대한 소유권을 주장하지 않습니다. 채팅 데이터는 게임 세션 기간 동안 저장되며, 게임 완료 후 삭제될 수 있습니다.

---

## 7. 광고

TalkBingo는 다음과 같은 광고를 표시할 수 있습니다:

- **배너 광고**: 게임 화면 하단에 표시.
- **전면 광고**: 게임 라운드 사이에 표시.
- **보상형 광고**: 포인트를 얻거나 기능을 잠금 해제하기 위해 선택적으로 시청하는 광고.

200 VP를 사용하여 개별 게임의 광고를 제거할 수 있습니다. 광고 환경 설정은 기기 설정에서 관리할 수 있습니다.

---

## 8. 면책 조항 및 책임 제한

서비스는 어떠한 종류의 보증 없이 "있는 그대로" 제공됩니다. 당사는 다음에 대해 책임을 지지 않습니다:

- 플레이어 간의 분쟁.
- 기기 고장이나 네트워크 문제로 인한 데이터 손실.
- 서비스의 일시적 사용 불가.
- 다른 사용자의 콘텐츠 또는 행동.

당사의 총 책임은 청구 이전 12개월 동안 당사에 지불한 금액을 초과하지 않습니다.

---

## 9. 해지 및 탈퇴

설정 페이지에서 언제든지 계정을 삭제할 수 있습니다. 삭제 시:

- 모든 개인 데이터가 서버에서 영구적으로 제거됩니다.
- 가상 화폐 및 게임 기록이 복구 불가능하게 삭제됩니다.
- 이 작업은 취소할 수 없습니다.

본 약관을 위반하는 경우 당사도 접근을 종료하거나 일시 중지할 수 있습니다.

---

## 10. 약관 변경

당사는 수시로 본 약관을 업데이트할 수 있습니다. 중요한 변경 사항은 앱을 통해 알립니다. 변경 후 서비스를 계속 사용하면 업데이트된 약관에 동의한 것으로 간주됩니다.

---

## 11. 연락처

본 약관에 대한 질문이 있으시면 아래로 연락해 주세요:

- **이메일**: talkbingohelp@gmail.com
- **웹사이트**: https://talkbingo.app
''',
      'guide_privacy_content': '''
# 개인정보 처리방침

**(최종 수정일: 2026년 2월)**

당사의 개인정보 보호 정책 및 관행과 귀하의 개인 데이터를 어떻게 취급하는지 이해하려면 본 개인정보 처리방침을 주의 깊게 읽어주세요.

본 개인정보 처리방침은 TalkBingo의 게임, 앱 및 관련 서비스(통칭 "서비스")에 적용됩니다. 본 개인정보 처리방침은 CAMMUPCO("회사", "당사", "우리")가 귀하("사용자", "회원")의 개인정보를 수집, 이용, 보호 및 공개하는 방법을 설명합니다.

---

## 목차

1. 수집하는 정보 및 수집 방법
2. 데이터 출처
3. 개인정보 이용 목적
4. 개인정보 보유 기간
5. 데이터 공유 및 제3자 제공
6. 국경 간 데이터 이전
7. 연령 제한
8. 귀하의 권리 및 선택
9. 데이터 보안
10. 개인정보 처리방침 변경
11. 연락처

---

## 1. 수집하는 정보 및 수집 방법

**귀하가 제공하는 정보:**

- **계정 정보**: 이메일 주소, 닉네임, 성별, 생년월일(선택), 프로필 사진(선택).
- **소통 데이터**: 게임 중 전송된 채팅 메시지 및 음성 녹음.
- **거래 데이터**: 인앱 구매 내역 및 가상 화폐 잔액.

**자동으로 수집되는 정보:**

- **기기 정보**: 기기 유형, 운영 체제, 브라우저 유형, 고유 기기 식별자.
- **이용 데이터**: 플레이한 게임 세션, 점수, 게임 플레이 패턴, 사용한 기능.
- **로그 데이터**: IP 주소, 접속 시간, 오류 로그.

---

## 2. 데이터 출처

다음 출처에서 데이터를 수집합니다:

- **귀하로부터 직접**: 계정 생성, 게임 플레이 또는 고객 지원 문의 시.
- **제3자 로그인**: Google 로그인 (이메일 및 프로필 정보).
- **자동화 도구**: 분석 및 오류 보고 서비스.
- **게임 파트너**: 게임 중 다른 플레이어와 상호 작용 시.

---

## 3. 개인정보 이용 목적

다음 목적으로 정보를 사용합니다:

- **서비스 제공**: 게임 플레이, 매치메이킹, 실시간 동기화 및 채팅 기능 제공.
- **개인화**: 관계 설정, 성별, 친밀도에 따른 게임 질문 맞춤화.
- **계정 관리**: 인증, 계정 복구 및 프로필 관리.
- **결제 처리**: 인앱 구매 처리 및 가상 화폐 관리.
- **분석**: 서비스 개선을 위한 이용 패턴 파악.
- **안전**: 사기, 부정 사용 탐지 및 이용 약관 시행.
- **광고**: 귀하의 선호도에 따른 관련 광고 표시.

---

## 4. 개인정보 보유 기간

- **활성 계정**: 계정이 활성 상태인 동안 데이터가 보유됩니다.
- **게임 세션 데이터**: 활성 게임 플레이 중 및 게임 완료 후 제한된 기간 동안 저장.
- **채팅 메시지**: 게임 세션 기간 동안 보유.
- **삭제된 계정**: 계정 삭제 후 30일 이내에 모든 개인 데이터가 영구 삭제됩니다.
- **익명/게스트 계정**: 앱 데이터를 삭제하거나 삭제를 요청할 때까지 데이터가 보유될 수 있습니다.

---

## 5. 데이터 공유 및 제3자 제공

당사는 귀하의 개인 데이터를 **판매하지 않습니다**. 다음과 데이터를 공유할 수 있습니다:

- **Supabase**: 인증, 데이터베이스 저장 및 실시간 기능을 위한 백엔드 인프라 제공업체.
- **Google**: 인증(Google 로그인) 및 광고(AdMob).
- **분석 제공업체**: 오류 보고 및 이용 통계 분석.
- **법적 기관**: 법률 또는 법적 절차에 의해 요구되는 경우.

모든 제3자 서비스는 각각의 개인정보 보호 정책 및 데이터 보호 계약에 따릅니다.

---

## 6. 국경 간 데이터 이전

귀하의 데이터는 미국 및 대한민국을 포함하여 귀하의 거주 국가 외의 국가로 이전되어 처리될 수 있습니다. 당사는 적용 가능한 데이터 보호법에 따라 귀하의 데이터를 보호하기 위한 적절한 안전 장치가 마련되어 있음을 보장합니다.

---

## 7. 연령 제한

TalkBingo는 14세 미만의 어린이를 대상으로 하지 않습니다. 당사는 14세 미만 어린이의 개인 데이터를 의도적으로 수집하지 않습니다. 그러한 데이터가 수집된 것을 발견하면 즉시 삭제하겠습니다.

---

## 8. 귀하의 권리 및 선택

귀하의 위치에 따라 다음과 같은 권리를 가질 수 있습니다:

- **접근권**: 개인 데이터의 사본을 요청할 수 있습니다.
- **정정권**: 부정확한 데이터의 정정을 요청할 수 있습니다.
- **삭제권**: 계정 및 모든 관련 데이터의 삭제를 요청할 수 있습니다 (설정 > 계정 삭제에서 가능).
- **데이터 이동권**: 이동 가능한 형식으로 데이터를 요청할 수 있습니다.
- **수신 거부**: 기기 설정을 통해 맞춤형 광고를 수신 거부할 수 있습니다.
- **동의 철회**: 언제든지 데이터 처리에 대한 동의를 철회할 수 있습니다.

**EU/EEA 거주자 (GDPR):** 현지 데이터 보호 당국에 불만을 제기할 권리가 있습니다.

**미국 캘리포니아 거주자 (CCPA):** 어떤 개인정보가 수집되는지 알 권리와 삭제를 요청할 권리가 있습니다. 당사는 개인정보를 판매하지 않습니다.

**권리 행사 방법:** 앱 내(설정 페이지)에서 대부분의 데이터 설정을 관리할 수 있습니다. 추가 요청은 아래 이메일로 연락해 주세요.

---

## 9. 데이터 보안

당사는 귀하의 데이터를 보호하기 위해 업계 표준 보안 조치를 구현합니다:

- **암호화**: 전송 중인 데이터는 TLS/SSL을 사용하여 암호화됩니다.
- **접근 제어**: 행 수준 보안(RLS) 정책으로 사용자가 자신의 데이터에만 접근할 수 있도록 보장합니다.
- **안전한 결제**: 포인트 거래는 변조를 방지하기 위해 서버 측 함수를 통해 처리됩니다.
- **인증**: Supabase Auth를 통한 안전한 토큰 기반 인증.

당사는 귀하의 데이터를 보호하기 위해 노력하지만, 전자 전송이나 저장 방법은 100% 안전하지 않습니다.

---

## 10. 개인정보 처리방침 변경

당사는 수시로 본 개인정보 처리방침을 업데이트할 수 있습니다. 중요한 변경 사항은 앱을 통해 알립니다. 변경 후 서비스를 계속 사용하면 동의한 것으로 간주됩니다.

---

## 11. 연락처

본 개인정보 처리방침에 대한 질문이 있거나 데이터 관련 권리를 행사하고자 하는 경우:

- **이메일**: talkbingohelp@gmail.com
- **웹사이트**: https://talkbingo.app

앱 내 설정에서 직접 개인정보 설정을 관리할 수도 있습니다.
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
