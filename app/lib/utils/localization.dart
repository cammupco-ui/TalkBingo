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
      'select_relation': 'Select your relationship with the guest',
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
      'customer_support': 'Customer Support',
      'bingo_guide': 'TalkBingo Guide',
      'points_guide': 'Point Guide',
      'terms': 'Terms of Service',
      'privacy': 'Privacy & Security',
      'version': 'Version',
      'guide_bingo': 'How to Play',
      'guide_points': 'Points Guide',
      'board_title': 'My Inquiries',
      'my_inquiries': 'My Inquiries',
      'public_board': 'Public / Notices',
      'notice_inquiry_btn': 'Contact us',
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
      'ad_free_title': 'Ad-Free Bingo',
      'ad_free_desc': 'Would you like to play ad-free bingo\nusing your points?',
      'ad_free_deduct': 'VP 25 will be deducted',
      'ad_free_current_vp': 'Current VP: ',
      'ad_free_current_cp': 'Current VP: ',
      'ad_free_use': 'Use 25 VP',
      'ad_free_skip': 'Play with Ads',
      'ad_free_not_enough': 'Not enough VP',
      'ad_free_not_enough_desc': 'Would you like to go to the\nPoint Management page?',
      'yes': 'Yes',
      'no': 'No',
      'rewarded_ad_title': 'Watch Ad → +5 VP',
      'rewarded_ad_remaining': '/10 remaining today',
      'rewarded_ad_watch': 'Watch',
      'rewarded_ad_done': 'Done',
      'rewarded_ad_earned': '+5 VP earned!',
      'rewarded_ad_limit': 'Daily limit reached (10/10)',
      'permanent_ad_removal': 'Remove Ads Permanently',
      'permanent_ad_removal_desc': 'No more ads, forever!',
      'permanent_ad_removal_cost': '8,000 VP',
      'permanent_ad_removal_confirm': 'This will use 8,000 VP to permanently remove all ads from TalkBingo.',
      'permanent_ad_removal_success': 'Ads removed permanently!\nEnjoy ad-free TalkBingo!',

      // Purchase Screen
      'purchase_title': 'Points & Ad-Free',
      'purchase_points_title': 'Purchase Points',
      'purchase_best_value': 'Best Value',
      'purchase_bonus': 'Bonus',
      'purchase_how_to_use': 'How to use VP?',
      'purchase_ad_remove_1game': 'Remove Ads (1 game): 25 VP',
      'purchase_ad_remove_permanent': 'Remove Ads (Permanent): 8,000 VP',
      'purchase_watch_ad_earn': 'Watch Ad: +5 VP (max 10/day)',
      'purchase_add_payment': 'Add Payment Method',
      'purchase_history': 'Transaction History',
      'purchase_free_tip': '💡 Watch ads daily to earn VP for free!',
      'purchase_view': 'View',
      'purchase_remaining_today': 'remaining today',
      'ad_catalog_title': 'Earn Free VP',
      'ad_catalog_subtitle': 'Watch ads to earn 5 VP each',
      'ad_cat_gaming': 'Gaming',
      'ad_cat_shopping': 'Shopping',
      'ad_cat_food': 'Food & Drink',
      'ad_cat_apps': 'Apps',
      'ad_cat_travel': 'Travel',
      'tier_bronze': 'Bronze',
      'tier_silver': 'Silver',
      'tier_gold': 'Gold',
      'tier_platinum': 'Platinum',
      'tier_king_royal': 'King Royal',
      'tier_queen_royal': 'Queen Royal',

      // Setup Screens
      'main_player': 'MainPlayer',
      'enter_nickname_hint': 'Enter your nickname',
      'nickname_validation': 'Nickname cannot be empty',
      'form_incomplete': '👆 Please enter nickname and select gender',
      'generate': 'Generate',
      'share': 'Share',
      'tap_to_copy': 'Send this code to your invitee',
      'code_copied': 'Code copied to clipboard!',
      'link_ready': 'Link is ready! (Copied to clipboard & Opening Share...)',
      'create_failed': 'Failed to create game session. Please try again.',

      // Guides
      'guide_read_confirm': 'I have read and understood the above.',
      'guide_confirm_btn': 'Confirm',

      'guide_bingo_content': '''

## 1️⃣ What is TalkBingo?

TalkBingo is a 1:1 communication game where you deepen your connection through natural conversation.
Get to know each other better through questions and mini games.

---

## 2️⃣ How to Play

1. Start a new game
2. Share the invite code
3. Take turns selecting cells

A conversation event begins on the selected cell.

---

## 3️⃣ Event Types

🃏 **Truth Game**
Answer honestly about yourself.
Your partner judges if it's sincere!

⚖️ **Balance Quiz**
Pick one option, then explain your reason.
Convince your partner and succeed!

🎮 **Mini Game**
Simple games like target shooting or penalty kicks to claim cells.

🔒 **Locked Cell**
If your partner disagrees, your cell gets locked!
When your turn comes around again, you get a chance to unlock it via a mini game. The winner claims the cell.

⚔️ **Challenge (Steal)**
You can challenge your opponent's cells (up to 2 times per game)!
The winner of the mini game takes the cell.

---

## 4️⃣ How to Win

If you succeed an event, you lock the cell.
Complete a row, column, or diagonal for BINGO!

---

## 5️⃣ What Makes It Special

✨ Conversations are automatically saved as memories.
✨ Questions match your relationship and intimacy level.
✨ Your opponent's disagreement can lock your cell — so try to earn their empathy when you answer!
✨ Challenge your partner's cells for exciting steals!

Start playing now 💬
''',

      'guide_points_content': '''
## 1️⃣ What Are Points?

TalkBingo has two types of points:
**GP** tracks your gameplay achievements, and **VP** unlocks premium features.

---

## 2️⃣ GP (Game Points)

Earned through gameplay. Accumulates permanently on your profile.

- Earn a cell: **+1 GP**
- Bingo line: **+20 GP** (2nd +40, 3rd +60)
- Steal a cell: **+10 GP**
- Defend a cell: **+5 GP**

Raise your badge tier by accumulating GP!

---

## 3️⃣ VP (Value Points)

Premium currency for special features.

**Earn VP:**
- 💳 In-App Purchase
- 📺 Rewarded Ads: **+5 VP** per ad (max 10/day)
- 🏆 Win a game: **+20 VP**

**Spend VP:**
- Ad-free game session: **25 VP**
- Permanent ad removal: **8,000 VP**
- More features coming soon!

---

## 4️⃣ Trust Score (TS)

⭐ Rated **1–5 stars** by your partner after each game.
Displayed on your profile to show your reliability.
Be polite and earn high trust from your partner!
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

- **GP (Game Points)**: Earned through gameplay. Used for cumulative stats and profile tracking.
- **VP (Value Points)**: Purchased with real money or earned via rewarded ads. Can be used to remove ads (25 VP per game).

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

You may remove ads for individual games by spending 25 VP. Ad preferences can be managed in your device settings.

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
      // Challenge & Notification Modals
      'challenge_confirm_title': 'Challenge Opponent?',
      'challenge_confirm_desc': 'Steal this tile by winning a Mini Game!\n\nAttempts: {remaining}/2',
      'challenge_btn': 'Challenge!',
      'challenge_initiated': '{name} challenged your cell! ({remaining}/2)',
      'challenge_initiated_other': '{name} challenged {owner}\'s cell! ({remaining}/2)',
      'disagree_notify': '{name} disagreed.',
      'disagree_unlock_hint': 'Unlock it on your next turn.',
      'disagree_unlock_hint_other': '{owner} can unlock it on their next turn.',
      'cell_won': '{name} captured the cell!',
      'cell_acquired': 'You acquired a cell! (Me: {me} | Opp: {opp})',
      'cell_lost': 'You lost a cell! (Me: {me} | Opp: {opp})',
      'cell_acquired_modal': 'You acquired a cell!',
      'cell_lost_modal': 'You lost a cell!',
      'cell_draw_modal': 'No cell changes!',
      'close_btn': 'Close',

      // ── Game Screen: Menu & Points ──
      'game_menu': 'Menu',
      'game_points_label': 'GP',
      'game_points_tooltip': 'View Points',
      'game_bingo_lines': 'Bingo Lines',
      'game_bingo_cells': 'Bingo Cells',
      'game_settings_title': 'Game Settings',
      'game_bgm': 'Background Music (BGM)',
      'game_sfx': 'Sound Effects (SFX)',
      'game_settings_label': 'Settings',
      'game_pause': 'Pause',
      'game_resume': 'Resume',
      'game_save': 'Save',
      'game_end': 'End Game',
      'game_saved': 'Saved!',
      'game_mic_permission': 'Microphone permission is required.',
      'game_recording_fail': 'Recording failed: ',
      'game_lang_switched_ko': 'Switched to Korean. (STT: Korean)',
      'game_lang_switched_en': 'Switched to English. (STT: English)',
      'game_paused': 'Game paused. Please wait.',
      'game_tile_taken': 'This tile is already taken!',
      'game_not_your_turn': "It's not your turn!",
      'game_locked_cooldown': '🔒 Locked! Cooldown active for {turns} turns.',
      'game_tile_locked': 'Tile Locked! 🔒',
      'game_interaction_in_progress': 'Interaction in progress! Please finish the quiz.',
      'game_reset_label': 'RESET',
      'game_state_reset': 'State Reset! Try clicking again.',
      'game_reset_failed': 'Reset Sync Failed: {error}. Local state cleared.',
      'game_challenge_bingo_line': 'Cannot challenge a completed Bingo line!',
      'game_no_challenges': 'No Challenge attempts remaining!',
      'game_waiting_ad': 'Waiting for opponent to finish ad...',
      'game_voice_sent': 'Voice message sent!',
      'game_voice_failed': 'Failed to send voice message.',
      'game_voice_too_short': 'Recording too short. Hold to record.',
      'game_over_title': 'Game Over! 🏁',
      'game_over_desc': 'The game has ended.\nProceed to collect your rewards!',
      'game_over_btn': 'Accept & Continue',
      'game_end_title': 'End Game?',
      'game_end_desc': 'Are you sure you want to end the game?',
      'game_restart_title': 'Restart Game?',
      'game_restart_desc': 'This will clear the board and reset turns.\nCurrent progress will be lost.',
      'game_restart_btn': 'Restart',
      'game_shuffle_started': 'Cannot shuffle once the game has started!',
      'game_shuffled': 'Questions Shuffled!',
      'game_saved_local': 'Game Saved Locally (Dev Mode)!',
      'game_login_required_save': 'You must be logged in to save!',
      'game_saved_cloud': 'Game Saved to Cloud!',
      'game_save_failed': 'Failed to save to Cloud.',
      'game_login_required_load': 'You must be logged in to load!',
      'game_load_failed': 'Failed to load from Cloud.',
      'game_no_saved': 'No saved game found.',
      'game_load_title': 'Load Saved Game?',
      'game_load_desc': 'Found a game saved on {date}. Load it?',
      'game_load_btn': 'Load',
      'game_loaded': 'Game Loaded!',
      'game_parse_failed': 'Failed to parse game data.',
      'guest_joined': '{name} has joined! 🎉',
      'bingo_ad_hint_prefix': 'After watching an ad, round ',

      // ── Quiz Overlay ──
      'quiz_opponent_choosing': 'Opponent is choosing...',
      'quiz_talk_empathy': 'Try to empathize through conversation',
      'quiz_disagree': 'Disagree',
      'quiz_agree': 'Agree',
      'quiz_submit': 'Submit',
      'quiz_opponent_answering': 'Opponent is answering...',
      'quiz_enter_answer': 'Enter or select an answer',
      'quiz_balance_hint': 'If both choose the same, you claim the cell.',

      // ── Game Tooltips ──
      'tip_chat_hello': 'Say hello! 👋',
      'tip_chat_ask': 'Ask questions if you\'re curious!',
      'tip_chat_empathy': 'Do you agree with their answer?',
      'tip_tap_confirm': 'Tap again to confirm!',
      'tip_locked_unlock': 'Tap again to challenge!',
      'tip_locked_cell': 'Try again after 3 turns!',
      'tip_challenge_hint': 'You can challenge up to 2 times!',
      'tip_challenge_remaining': '{remaining}/2 chances!',
      'tip_bingo_untouchable': 'Bingo cells can\'t be touched!',
      'tip_type_message': 'Type a message...',

      // ── Report Dialog ──
      'report_title': 'Report Question',
      'report_typo': 'Typo',
      'report_weird': 'Weird Content',
      'report_other': 'Other',
      'report_sent': 'Report has been submitted.',

      // ── Mini-Game Coach Marks ──
      'mini_coach_penalty': 'Swipe toward the goal to shoot!',
      'mini_coach_target': 'Pull back to shoot the arrow!',
      'mini_game_arrow_instruction': 'Shoot as many arrows as possible!',
      'mini_game_kick_instruction': 'Shoot for the most goals!',
      'mini_coach_dismiss': 'Don\'t show again',

      // ── Power Gauge ──
      'power_gauge_tip': 'Green zone is optimal power',

      // ── Floating Button ──
      'floating_board': 'Board',

      // ── Home Screen ──
      'home_points_benefit': 'Earn points & keep records!',
      'home_register_prompt': 'Register to get benefits.',
      'home_register_btn': 'Register',
      'home_guest_confirm': 'Join as Guest Mode?',
      'home_guest_code': 'Code',

      // ── Sign Out Landing ──
      'signout_title': 'See you again!',
      'signout_subtitle': "We'll be here so your story never stops.",

      // ── Notice Screen ──
      'notice_category': 'Category',
      'notice_content': 'Content',
      'notice_content_hint': 'Please describe your inquiry in detail.',
      'notice_contact': 'Contact (Email/Phone)',
      'notice_contact_hint': 'Enter only if you want a reply.',
      'notice_cancel': 'Cancel',
      'notice_send': 'Send',
      'notice_ask': 'Ask',
      'notice_content_required': 'Please enter content.',
      'notice_submitted': 'Inquiry submitted successfully.\nThank you for your feedback!',
      'notice_confirm': 'OK',
      'notice_server_error': 'Server configuration error: contact admin (Table Missing).',
      'notice_send_fail': 'Send failed: ',
      'notice_loading_error': 'Error loading notices.',
      'notice_cat_bug': 'Bug Report',
      'notice_cat_feature': 'Feature Suggestion',
      'notice_cat_other': 'Other Inquiry',

      // ── Host Setup Screen ──
      'host_invite_msg': 'An invitation has arrived! 💌\n',
      'host_invite_code': 'Participation Code: ',
      'host_invite_link': 'Join now: ',

      // ── Auth Error Messages ──
      'auth_error_invalid_credentials': 'Incorrect email or password.',
      'auth_error_email_not_confirmed': 'Email not verified. Please check your email.',
      'auth_error_user_not_found': 'No account found with this email.',
      'auth_error_too_many_requests': 'Too many attempts. Please try again later.',
      'auth_error_already_registered': 'This email is already registered.',
      'auth_error_weak_password': 'Password must be at least 6 characters.',
      'auth_error_invalid_email': 'Please enter a valid email address.',
      'auth_error_network': 'Unable to connect to server. Please check your internet connection.',
      'auth_error_generic': 'An error occurred. Please try again.',
      'auth_error_fill_all': 'Please enter email and password.',
      'auth_error_fill_all_fields': 'Please fill in all fields.',

      // ── Signup Screen ──
      'signup_network_error': 'Server connection is unstable. (Network Error)\nPlease refresh and try again.',

      // ── Splash Screen ──
      'splash_1': 'Love yourself',
      'splash_2': 'Here, just being you is enough',
      'splash_3': 'Start as who you are now',
      'splash_4': 'There\'s no right answer, just your story',
      'splash_5': 'Even if you go slow, you\'re on the right path',
      'splash_6': 'It\'s okay not to try too hard',
      'splash_7': 'This moment is your time',
      'splash_8': 'You shine without comparison',
      'splash_9': 'Just be ready to be honest',
      'splash_10': 'Respect your own pace',
      'splash_11': 'You\'re already enough to begin',

      // ── Coach Mark: Home Screen ──
      'coach_home_new_game': 'Set up a game and invite someone to talk!',
      'coach_home_join': 'Jump right into a game with an invite code!',
      'coach_home_resume': 'Return to your ongoing game',
      'coach_home_settings': 'Manage your profile & settings',

      // ── Coach Mark: Game Screen ──
      'coach_game_board': 'Answer questions and complete your bingo!',
      'coach_game_ticker': 'Tap to open chat, or drag me around!',
      'coach_game_chat': 'Type a message or send one with your voice 🎤',
      'coach_game_header': 'Check your game status',

      // ── Coach Mark: UI ──
      'coach_skip': 'Skip',
      'coach_next': 'Next',
      'coach_done': 'Got it!',
      'coach_dont_show': "Don't show again",
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
      'guest_settings': '초대자 설정',
      'select_relation': '상대방과의 관계를 선택하세요',
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
      'customer_support': '고객 지원',
      'bingo_guide': '톡빙고 게임 하는법',
      'points_guide': '포인트 가이드',
      'terms': '서비스 약관 및 라이센스',
      'privacy': '개인정보 보호정책',
      'version': '버전',
      'guide_bingo': '빙고 플레이 방법',
      'guide_points': '포인트 사용 방법',
      'board_title': '내 문의 내역',
      'my_inquiries': '내 문의 내역',
      'public_board': '공지사항 / 전체글',
      'notice_inquiry_btn': '고객문의',
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
      'ad_free_title': '광고 없는 빙고',
      'ad_free_desc': '포인트를 사용하여\n전면광고 없는 빙고를 하시겠습니까?',
      'ad_free_deduct': 'VP 25 차감',
      'ad_free_current_vp': '현재 VP: ',
      'ad_free_current_cp': '현재 VP: ',
      'ad_free_use': '25 VP 사용',
      'ad_free_skip': '광고 있는 게임',
      'ad_free_not_enough': 'VP가 부족합니다',
      'ad_free_not_enough_desc': '포인트 관리 페이지로\n이동하시겠습니까?',
      'yes': '예',
      'no': '아니오',
      'rewarded_ad_title': '광고 시청 → +5 VP',
      'rewarded_ad_remaining': '/10 오늘 남은 횟수',
      'rewarded_ad_watch': '시청',
      'rewarded_ad_done': '완료',
      'rewarded_ad_earned': '+5 VP 획득!',
      'rewarded_ad_limit': '일일 한도 도달 (10/10)',
      'permanent_ad_removal': '영구 광고 제거',
      'permanent_ad_removal_desc': '광고 없이 영원히!',
      'permanent_ad_removal_cost': '8,000 VP',
      'permanent_ad_removal_confirm': '8,000 VP를 사용하여 TalkBingo의 모든 광고를 영구적으로 제거합니다.',
      'permanent_ad_removal_success': '광고가 영구적으로 제거되었습니다!\n광고 없는 TalkBingo를 즐기세요!',

      // Purchase Screen
      'purchase_title': '포인트 & 광고제거',
      'purchase_points_title': '포인트 구매',
      'purchase_best_value': '최고 가성비',
      'purchase_bonus': '보너스',
      'purchase_how_to_use': 'VP 사용법',
      'purchase_ad_remove_1game': '광고 제거 (1게임): 25 VP',
      'purchase_ad_remove_permanent': '광고 제거 (영구): 8,000 VP',
      'purchase_watch_ad_earn': '광고 시청: +5 VP (하루 최대 10회)',
      'purchase_add_payment': '결제 수단 등록',
      'purchase_history': '거래 내역',
      'purchase_free_tip': '💡 매일 광고를 보고 무료 VP를 모으세요!',
      'purchase_view': '보기',
      'purchase_remaining_today': '오늘 남은 횟수',
      'ad_catalog_title': '무료 VP 받기',
      'ad_catalog_subtitle': '광고를 보고 5 VP씩 획득하세요',
      'ad_cat_gaming': '게임',
      'ad_cat_shopping': '쇼핑',
      'ad_cat_food': '음식',
      'ad_cat_apps': '앱',
      'ad_cat_travel': '여행',
      'tier_bronze': '브론즈',
      'tier_silver': '실버',
      'tier_gold': '골드',
      'tier_platinum': '플래티넘',
      'tier_king_royal': '킹 로열',
      'tier_queen_royal': '퀸 로열',

      // Setup Screens
      'main_player': '메인플레이어',
      'enter_nickname_hint': '당신의 별명을 입력하세요',
      'nickname_validation': '닉네임을 입력해 주세요',
      'form_incomplete': '👆 닉네임을 입력하고 성별을 선택해 주세요',
      'generate': '생성하기',
      'share': '초대코드 보내기',
      'tap_to_copy': '초청자에게 이 코드를 보내세요',
      'code_copied': '코드가 클립보드에 복사되었습니다!',
      'link_ready': '링크가 준비되었습니다! (클립보드에 복사 및 공유 열기...)',
      'create_failed': '게임 세션 생성에 실패했습니다. 다시 시도해 주세요.',

      // Guides
      'guide_read_confirm': '위 내용을 모두 확인했습니다.',
      'guide_confirm_btn': '확인',
      
      'guide_bingo_content': '''

## 1️⃣ TalkBingo란?

TalkBingo는 게임을 통해 자연스럽게 대화를 이어가는 1:1 커뮤니케이션 게임입니다.
질문과 미니게임을 통해 서로를 더 깊이 알아가세요.

---

## 2️⃣ 게임 방법

1. 새 게임을 시작하세요
2. 초대코드를 공유하세요
3. 번갈아 가며 셀을 선택하세요

선택한 셀에서 이벤트가 시작됩니다.

---

## 3️⃣ 이벤트 종류

🃏 **진실 게임**
나에 대한 질문에 솔직하게 답변하세요.
상대가 진심인지 판단합니다!

⚖️ **밸런스 퀴즈**
선택 후, 이유를 설명하세요.
상대가 납득하면 성공!

🎮 **미니게임**
화살, 승부차기 등 간단한 게임으로 셀을 획득하세요.

🔒 **잠김 셀**
상대방의 비공감으로 셀이 잠길 수 있습니다!
잠김 셀은 해당 유저의 다음 턴에 미니게임으로 풀 수 있는 기회가 주어지며, 미니게임 승자가 셀을 획득합니다.

⚔️ **도전 (빼앗기)**
상대가 가진 셀에 도전할 수 있습니다 (게임당 최대 2회)!
미니게임의 승리로 셀을 획득합니다.

---

## 4️⃣ 이기는 법

이벤트에 성공하면 셀을 차지합니다.
가로·세로·대각선으로 빙고를 완성하세요!

---

## 5️⃣ 특별한 점

✨ 대화가 자동으로 추억 콘텐츠로 저장됩니다.
✨ 관계에 맞춰 질문 난이도가 달라집니다.
✨ 상대방의 비공감에 의해 셀이 잠길 수 있어요 — 답변할 때 상대의 공감을 이끌어내세요!
✨ 상대 셀에 도전하는 스릴 넘치는 빼앗기!

지금 시작해보세요 💬
''',

      'guide_points_content': '''
## 1️⃣ 포인트란?

TalkBingo에는 두 가지 포인트가 있습니다.
**GP**는 게임 활동을 기록하고, **VP**는 프리미엄 기능을 잠금 해제합니다.

---

## 2️⃣ GP (게임 포인트)

게임 플레이로 획득. 프로필에 영구 누적됩니다.

- 셀 획득: **+1 GP**
- 빙고 라인: **+20 GP** (2줄째 +40, 3줄째 +60)
- 셀 빼앗기: **+10 GP**
- 셀 방어: **+5 GP**

GP점수 누적으로 보상뱃지 등급을 높이세요.

---

## 3️⃣ VP (밸류 포인트)

특별 기능을 위한 프리미엄 화폐입니다.

**획득 방법:**
- 💳 인앱 결제
- 📺 보상형 광고: **+5 VP** (하루 최대 10회)
- 🏆 게임 승리: **+20 VP**

**사용처:**
- 광고 없는 게임: **25 VP**
- 영구 광고 제거: **8,000 VP**
- 더 많은 기능이 곧 추가됩니다!

---

## 4️⃣ 신뢰도 점수 (TS)

⭐ 게임 종료 후 상대방이 **1~5점**으로 평가합니다.
프로필에 표시되어 나의 신뢰도를 보여줍니다.
매너있는 대화로 상대방에게 높은 신뢰를 얻어보세요!
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

- **GP (Game Points)**: 게임 플레이를 통해 획득. 누적 통계 및 프로필 추적에 사용.
- **VP (Value Points)**: 실제 결제 또는 보상형 광고로 획득. 광고 제거(게임당 25 VP)에 사용 가능.

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

25 VP를 사용하여 개별 게임의 광고를 제거할 수 있습니다. 광고 환경 설정은 기기 설정에서 관리할 수 있습니다.

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
      // Challenge & Notification Modals
      'challenge_confirm_title': '셀 빼앗기 도전?',
      'challenge_confirm_desc': '미니게임에서 이기면 셀을 빼앗을 수 있습니다!\n\n남은 도전: {remaining}/2',
      'challenge_btn': '도전!',
      'challenge_initiated': '{name}님이 당신의 셀에 도전하셨습니다! ({remaining}/2)',
      'challenge_initiated_other': '{name}님이 {owner}님의 셀에 도전하셨습니다! ({remaining}/2)',
      'disagree_notify': '{name}님이 비공감 하셨습니다.',
      'disagree_unlock_hint': '다음 당신의 차례에 잠금을 푸세요.',
      'disagree_unlock_hint_other': '다음 {owner}님의 차례에 잠금을 풀 수 있어요.',
      'cell_won': '{name}님이 셀을 획득하셨습니다!',
      'cell_acquired': '셀을 획득했습니다! (나: {me} | 상대: {opp})',
      'cell_lost': '셀을 잃었습니다! (나: {me} | 상대: {opp})',
      'cell_acquired_modal': '셀을 획득하셨습니다!',
      'cell_lost_modal': '셀을 잃으셨습니다!',
      'cell_draw_modal': '셀 변동이 없습니다!',
      'close_btn': '닫기',

      // ── Game Screen: Menu & Points ──
      'game_menu': '메뉴',
      'game_points_label': 'GP',
      'game_points_tooltip': '포인트 보기',
      'game_bingo_lines': '빙고줄',
      'game_bingo_cells': '빙고셀',
      'game_settings_title': '게임 설정',
      'game_bgm': '배경음악 (BGM)',
      'game_sfx': '효과음 (SFX)',
      'game_settings_label': '설정',
      'game_pause': '잠시 멈춤',
      'game_resume': '다시 시작',
      'game_save': '저장하기',
      'game_end': '종료하기',
      'game_saved': '저장되었습니다.',
      'game_mic_permission': '마이크 권한이 필요합니다.',
      'game_recording_fail': '녹음 시작 실패: ',
      'game_lang_switched_ko': '한국어로 변경되었습니다. (STT: 한국어)',
      'game_lang_switched_en': 'Switched to English. (STT: English)',
      'game_paused': '게임이 일시 정지 중입니다.',
      'game_tile_taken': '이미 선택된 칸입니다!',
      'game_not_your_turn': '상대방의 차례입니다!',
      'game_locked_cooldown': '🔒 잠김! {turns}턴 후 도전 가능합니다.',
      'game_tile_locked': '칸이 잠겼습니다! 🔒',
      'game_interaction_in_progress': '퀴즈가 진행 중입니다! 먼저 완료해 주세요.',
      'game_reset_label': '초기화',
      'game_state_reset': '상태가 초기화되었습니다! 다시 눌러보세요.',
      'game_reset_failed': '초기화 실패: {error}. 로컬 상태를 초기화했습니다.',
      'game_challenge_bingo_line': '완성된 빙고줄은 도전할 수 없습니다!',
      'game_no_challenges': '도전 횟수가 남아있지 않습니다!',
      'game_waiting_ad': '상대방의 광고 시청을 기다리는 중...',
      'game_voice_sent': '음성 메시지가 전송되었습니다!',
      'game_voice_failed': '음성 메시지 전송에 실패했습니다.',
      'game_voice_too_short': '녹음이 너무 짧습니다. 길게 눌러 녹음하세요.',
      'game_over_title': '게임 종료! 🏁',
      'game_over_desc': '게임이 끝났습니다.\n보상을 받으러 가볼까요!',
      'game_over_btn': '확인 및 계속',
      'game_end_title': '게임을 끝낼까요?',
      'game_end_desc': '정말 게임을 끝내시겠습니까?',
      'game_restart_title': '게임을 다시 시작할까요?',
      'game_restart_desc': '보드가 초기화되고 턴이 리셋됩니다.\n현재 진행 상황이 사라집니다.',
      'game_restart_btn': '다시 시작',
      'game_shuffle_started': '게임이 시작된 후에는 섞을 수 없습니다!',
      'game_shuffled': '질문이 섞였습니다!',
      'game_saved_local': '로컬에 저장되었습니다 (Dev Mode)!',
      'game_login_required_save': '저장하려면 로그인이 필요합니다!',
      'game_saved_cloud': '클라우드에 저장되었습니다!',
      'game_save_failed': '클라우드 저장에 실패했습니다.',
      'game_login_required_load': '불러오려면 로그인이 필요합니다!',
      'game_load_failed': '클라우드에서 불러오기 실패했습니다.',
      'game_no_saved': '저장된 게임이 없습니다.',
      'game_load_title': '저장된 게임을 불러올까요?',
      'game_load_desc': '{date}에 저장된 게임을 발견했습니다. 불러올까요?',
      'game_load_btn': '불러오기',
      'game_loaded': '게임을 불러왔습니다!',
      'game_parse_failed': '게임 데이터를 읽는데 실패했습니다.',
      'guest_joined': '{name} 님이 입장했습니다 🎉',
      'bingo_ad_hint_prefix': '광고 시청 후 ',

      // ── Quiz Overlay ──
      'quiz_opponent_choosing': '상대방이 선택 중입니다...',
      'quiz_talk_empathy': '공감 할수 있게 대화 해 보세요',
      'quiz_disagree': '비공감',
      'quiz_agree': '공감',
      'quiz_submit': '확인',
      'quiz_opponent_answering': '상대방이 답변 중입니다...',
      'quiz_enter_answer': '답변을 입력하거나 선택하세요',
      'quiz_balance_hint': '둘이 같은 선택이면 칸을 차지합니다.',

      // ── Game Tooltips ──
      'tip_chat_hello': '서로 인사를 나눠요! 👋',
      'tip_chat_ask': '궁금한 점이 있으면 물어보세요!',
      'tip_chat_empathy': '상대방의 의견에 공감하시나요?',
      'tip_tap_confirm': '한번 더 누르면 선택확정!',
      'tip_locked_unlock': '한번 더 누르면 도전!',
      'tip_locked_cell': '3턴 후에 다시 도전!',
      'tip_challenge_hint': '최대 2번 도전 할수 있어요!',
      'tip_challenge_remaining': '{remaining}/2 기회!',
      'tip_bingo_untouchable': '빙고셀은 터치불가!',
      'tip_type_message': '메시지를 입력하세요...',

      // ── Report Dialog ──
      'report_title': '질문 신고하기',
      'report_typo': '맞춤법 오류 (Typo)',
      'report_weird': '내용 이상함 (Weird)',
      'report_other': '기타 (Other)',
      'report_sent': '신고가 접수되었습니다.',

      // ── Mini-Game Coach Marks ──
      'mini_coach_penalty': '골대 방향으로 밀어서 슛!',
      'mini_coach_target': '활시위를 당겨서 발사!',
      'mini_game_arrow_instruction': '최대한 많은 화살을 쏘세요!',
      'mini_game_kick_instruction': '최대한 많은 골을 넣으세요!',
      'mini_coach_dismiss': '다신 안보기',

      // ── Power Gauge ──
      'power_gauge_tip': '초록 구간이 최적 파워',

      // ── Floating Button ──
      'floating_board': '보드',

      // ── Home Screen ──
      'home_points_benefit': '포인트 적립과 기록 보존!',
      'home_register_prompt': '계정을 등록하고 혜택을 받으세요.',
      'home_register_btn': '등록',
      'home_guest_confirm': 'Guest Mode로 참여하시겠습니까?',
      'home_guest_code': '코드',

      // ── Sign Out Landing ──
      'signout_title': '우리 다시 만나요!',
      'signout_subtitle': '당신의 이야기가 멈추지 않도록 곁에 있을게요',

      // ── Notice Screen ──
      'notice_category': '카테고리',
      'notice_content': '내용',
      'notice_content_hint': '문의하실 내용을 자세히 적어주세요.',
      'notice_contact': '연락처 (이메일/전화번호)',
      'notice_contact_hint': '답변을 받으실 분만 입력해주세요.',
      'notice_cancel': '취소',
      'notice_send': '보내기',
      'notice_ask': '문의하기',
      'notice_content_required': '내용을 입력해주세요.',
      'notice_submitted': '문의가 성공적으로 접수되었습니다.\n소중한 의견 감사합니다!',
      'notice_confirm': '확인',
      'notice_server_error': '서버 설정 오류: 관리자에게 문의하세요 (Table Missing).',
      'notice_send_fail': '전송 실패: ',
      'notice_loading_error': '공지사항을 불러오는 중 오류가 발생했습니다.',
      'notice_cat_bug': '버그 신고',
      'notice_cat_feature': '기능 제안',
      'notice_cat_other': '기타 문의',

      // ── Host Setup Screen ──
      'host_invite_msg': '초대장이 도착했습니다! 💌\n',
      'host_invite_code': '참여 코드: ',
      'host_invite_link': '바로 입장하기: ',

      // ── Auth Error Messages ──
      'auth_error_invalid_credentials': '이메일 또는 비밀번호가 잘못되었습니다.',
      'auth_error_email_not_confirmed': '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요.',
      'auth_error_user_not_found': '등록되지 않은 이메일입니다.',
      'auth_error_too_many_requests': '시도 횟수가 너무 많습니다. 잠시 후 다시 시도해주세요.',
      'auth_error_already_registered': '이미 가입된 이메일입니다.',
      'auth_error_weak_password': '비밀번호는 6자 이상이어야 합니다.',
      'auth_error_invalid_email': '올바른 이메일 주소를 입력해주세요.',
      'auth_error_network': '서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.',
      'auth_error_generic': '오류가 발생했습니다. 다시 시도해주세요.',
      'auth_error_fill_all': '이메일과 비밀번호를 입력해주세요.',
      'auth_error_fill_all_fields': '모든 항목을 입력해주세요.',

      // ── Signup Screen ──
      'signup_network_error': '서버 연결 상태가 불안정합니다. (Network Error)\n새로고침 후 다시 시도해주세요.',

      // ── Splash Screen ──
      'splash_1': '스스로를 사랑하세요',
      'splash_2': '여기서는 너 그대로면 충분해',
      'splash_3': '지금의 너로 시작하면 돼',
      'splash_4': '정답은 없어 네 이야기면 돼',
      'splash_5': '천천히 가도 방향은 맞아',
      'splash_6': '잘하려 하지 않아도 괜찮아',
      'splash_7': '이 순간은 너를 위한 시간이야',
      'splash_8': '비교하지 않아도 빛나',
      'splash_9': '솔직해질 준비만 있으면 돼',
      'splash_10': '너의 속도를 존중해',
      'splash_11': '시작하기에 이미 충분해',

      // ── Coach Mark: Home Screen ──
      'coach_home_new_game': '게임 세팅하고, 대화 할 사람을 초청하세요!',
      'coach_home_join': '초대받은 코드로 게임에 바로 입장하세요!',
      'coach_home_resume': '진행 중인 게임으로 돌아갈 수 있어요',
      'coach_home_settings': '프로필과 설정을 관리하세요',

      // ── Coach Mark: Game Screen ──
      'coach_game_board': '질문에 답하면서, 빙고를 완성하세요!',
      'coach_game_ticker': '탭하면 채팅보드, 저를 움직여 보세요!',
      'coach_game_chat': '키보드나 음성🎤으로 메세지를 보내세요!',
      'coach_game_header': '게임의 상태를 확인하세요',

      // ── Coach Mark: UI ──
      'coach_skip': '건너뛰기',
      'coach_next': '다음',
      'coach_done': '확인!',
      'coach_dont_show': '다시 보지 않기',
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
