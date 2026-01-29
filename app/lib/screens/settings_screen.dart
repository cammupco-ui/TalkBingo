import 'dart:math';
import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/screens/sign_out_landing_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/point_purchase_screen.dart';
import 'package:talkbingo_app/utils/migration_manager.dart';
// import 'package:talkbingo_app/screens/splash_screen.dart'; // Removed to avoid circular dependency
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/screens/signup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nicknameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _snsController = TextEditingController();
  final _addressController = TextEditingController();
  final GameSession _session = GameSession(); // Added for easier access
  
  String? _selectedAge;
  String? _selectedGender;
  String? _selectedProvince;
  String? _selectedCity;
  
  bool _regionConsent = false;
  
  bool _hasChanges = false; // Track unsaved changes
  bool _isSaving = false; // Track saving state

  final List<String> _ageGroups = ['10s', '20s', '30s', '40s', '50s', '60s+'];
  
  // Reusing Hometown Data (Should be shared, but copying for now for speed)
  final Map<String, List<String>> _hometownData = {
    '서울특별시': ['강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구', '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구', '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구'],
    '부산광역시': ['강서구', '금정구', '기장군', '남구', '동구', '동래구', '부산진구', '북구', '사상구', '사하구', '서구', '수영구', '연제구', '영도구', '중구', '해운대구'],
    '대구광역시': ['남구', '달서구', '달성군', '동구', '북구', '서구', '수성구', '중구', '군위군'],
    '인천광역시': ['계양구', '남동구', '동구', '미추홀구', '부평구', '서구', '연수구', '중구', '강화군', '옹진군'],
    '광주광역시': ['광산구', '남구', '동구', '북구', '서구'],
    '대전광역시': ['대덕구', '동구', '서구', '유성구', '중구'],
    '울산광역시': ['남구', '동구', '북구', '중구', '울주군'],
    '세종특별자치시': ['세종시'],
    '강원특별자치도': ['강릉시', '고성군', '동해시', '삼척시', '속초시', '양구군', '양양군', '영월군', '원주시', '인제군', '정선군', '철원군', '춘천시', '태백시', '평창군', '홍천군', '화천군', '횡성군'],
    '충청북도': ['괴산군', '단양군', '보은군', '영동군', '옥천군', '음성군', '제천시', '증평군', '진천군', '청주시', '충주시'],
    '충청남도': ['계룡시', '공주시', '금산군', '논산시', '당진시', '보령시', '부여군', '서산시', '서천군', '아산시', '예산군', '천안시', '청양군', '태안군', '홍성군'],
    '전북특별자치도': ['고창군', '군산시', '김제시', '남원시', '무주군', '부안군', '순창군', '완주군', '익산시', '임실군', '장수군', '전주시', '정읍시', '진안군'],
    '전라남도': ['강진군', '고흥군', '곡성군', '광양시', '구례군', '나주시', '담양군', '목포시', '무안군', '보성군', '순천시', '신안군', '여수시', '영광군', '영암군', '완도군', '장성군', '장흥군', '진도군', '함평군', '해남군', '화순군'],
    '경상북도': ['경산시', '경주시', '고령군', '구미시', '김천시', '문경시', '봉화군', '상주시', '성주군', '안동시', '영덕군', '영양군', '영주시', '영천시', '예천군', '울릉군', '울진군', '의성군', '청도군', '청송군', '칠곡군', '포항시'],
    '경상남도': ['거제시', '거창군', '고성군', '김해시', '남해군', '밀양시', '사천시', '산청군', '양산시', '의령군', '진주시', '창녕군', '창원시', '통영시', '하동군', '함안군', '함양군', '합천군'],
    '제주특별자치도': ['서귀포시', '제주시'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadData();
    
    // Add listeners to detect changes
    _nicknameController.addListener(_checkForChanges);
    _birthDateController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _snsController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _snsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final session = GameSession();
    // Simple check: compare current values with session values
    // Note: For dropdowns, we handle in onChanged
    bool hasChanged = 
        _nicknameController.text != (session.hostNickname ?? '') ||
        _birthDateController.text != (session.hostBirthDate ?? '') ||
        _phoneController.text != (session.hostPhone ?? '') ||
        _snsController.text != (session.hostSns ?? '') ||
        _addressController.text != (session.hostAddress ?? '') ||
        _regionConsent != (session.hostRegionConsent ?? false) ||
        _selectedAge != session.hostAge ||
        _selectedGender != session.hostGender ||
        _selectedProvince != session.hostHometownProvince ||
        _selectedCity != session.hostHometownCity;
        
    setState(() {
      _hasChanges = hasChanged;
    });
  }

  Future<void> _loadData() async {
    // Payment load removed
    if (mounted) _loadUserData();
  }

  void _loadUserData() {
    final session = GameSession();
    _nicknameController.text = session.hostNickname ?? '';
    _birthDateController.text = session.hostBirthDate ?? '';
    _phoneController.text = session.hostPhone ?? '';
    _snsController.text = session.hostSns ?? '';
    _addressController.text = session.hostAddress ?? '';
    _regionConsent = session.hostRegionConsent ?? false;

    _selectedAge = session.hostAge;
    _selectedGender = session.hostGender;
    _selectedProvince = session.hostHometownProvince;
    _selectedCity = session.hostHometownCity;
    
    setState(() {
      _hasChanges = false; // Reset change tracking after load
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    // Simulate slight delay for visual feedback if save is too fast
    await Future.delayed(const Duration(milliseconds: 500));

    final session = GameSession();
    session.hostNickname = _nicknameController.text;
    session.hostBirthDate = _birthDateController.text;
    session.hostPhone = _phoneController.text;
    session.hostSns = _snsController.text;
    session.hostAddress = _addressController.text;
    session.hostRegionConsent = _regionConsent;
    
    session.hostAge = _selectedAge;
    session.hostGender = _selectedGender;
    session.hostHometownProvince = _selectedProvince;
    session.hostHometownCity = _selectedCity;
    
    await session.saveHostInfoToPrefs(); // Persist updates
    
    // Payment save removed
    
    setState(() {
        _hasChanges = false;
        _isSaving = false;
    });
    
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('settings_saved')), backgroundColor: AppColors.hostPrimary),
        );
    }
  }

  Future<void> _launchFeedback() async {
     const url = 'https://docs.google.com/forms'; // TODO: Replace with your actual Google Form URL
     final uri = Uri.parse(url);
     if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
     } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open feedback form.'))
           );
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    // Hide Ad on Settings Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = false;
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()), 
              (route) => false,
            );
          },
          child: SvgPicture.asset(
            'assets/images/Logo Vector.svg',
            height: 30,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent scroll tint
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Game Points Section
            const SizedBox(height: 16),
            _buildPointsOverview(),
            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 32),

            // 2. App Settings Section
            _buildSectionHeader(AppLocalizations.get('app_settings')),
            const SizedBox(height: 12),
            
            // Language Selection
            _buildLabel(AppLocalizations.get('language'), isRequired: true),
            Row(
              children: [
                _buildLanguageChip('English', 'en'),
                const SizedBox(width: 10),
                _buildLanguageChip('한국어', 'ko'),
              ],
            ),
            const SizedBox(height: 24),

            // Feedback / Support
            _buildLabel(AppLocalizations.get('support')),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchFeedback,
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: Text(AppLocalizations.get('send_feedback')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 24),

            // 3. Profile Section
            _buildSectionHeader(AppLocalizations.get('profile_settings')),
            const SizedBox(height: 12),
            
            // Registered Email (Read Only)
            _buildLabel(AppLocalizations.get('account_email'), isRequired: true),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Light Grey for engraved feel
                borderRadius: BorderRadius.circular(8),
                // No border for engraved look
              ),
              child: Text(
                Supabase.instance.client.auth.currentUser?.email ?? 'No Details',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),

            // Nickname
            _buildLabel(AppLocalizations.get('nickname'), isRequired: true),
            TextField(
              controller: _nicknameController,
              decoration: _inputDecoration('Nickname'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Gender
            _buildLabel(AppLocalizations.get('gender'), isRequired: true),
            Row(
              children: [
                _buildGenderChip(AppLocalizations.get('male'), 'Male'),
                const SizedBox(width: 10),
                _buildGenderChip(AppLocalizations.get('female'), 'Female'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Birth Date
            _buildLabel(AppLocalizations.get('birth_date'), isRequired: true),
            TextField(
              controller: _birthDateController,
              decoration: _inputDecoration('YYYY-MM-DD'),
              keyboardType: TextInputType.datetime,
              style: const TextStyle(fontSize: 14),
            ),
             const SizedBox(height: 24),
             // Separator: Thin Grey Dotted Line
             // Separator: Solid Grey Line
             Divider(color: Colors.grey[300], height: 1, thickness: 1),
             const SizedBox(height: 24),

            // SNS
            _buildLabel(AppLocalizations.get('sns')),
            TextField(
              controller: _snsController,
              decoration: _inputDecoration('@username'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

             // Address
            _buildLabel(AppLocalizations.get('address')),
            TextField(
              controller: _addressController,
               decoration: _inputDecoration('City, District'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
             // Phone
            _buildLabel(AppLocalizations.get('phone_number')),
            TextField(
              controller: _phoneController,
              decoration: _inputDecoration('010-1234-5678'),
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            // Region Consent
            // Region Consent (Styled like Input)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Match Input Background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(AppLocalizations.get('allow_region'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, color: Colors.black87))),
                   SizedBox(
                     height: 30, 
                     child: Transform.scale(
                       scale: 0.8,
                       child: Switch(
                        activeColor: AppColors.hostPrimary,
                        activeTrackColor: AppColors.hostPrimary.withOpacity(0.2),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                        trackOutlineColor: MaterialStateProperty.all(Colors.transparent), // Remove Outline
                        value: _regionConsent, 
                        onChanged: (val) {
                          setState(() {
                            _regionConsent = val;
                            _checkForChanges();
                          });
                        }
                       ),
                     ),
                   )
                ],
              ),
            ),

            // Personal Info Retention Consent
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(AppLocalizations.get('agree_retention'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              subtitle: Text(AppLocalizations.get('retention_sub'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontSize: 12, color: Colors.grey))),
              activeColor: AppColors.hostPrimary,
              value: true, // Mocking consent as always true or managed state if needed. User just asked for checkbox.
              onChanged: (val) {
                 // No-op or manage state if strictly required.
              },
            ),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hostPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving 
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Text(AppLocalizations.get('save_changes'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ),
            ),

            const SizedBox(height: 8),
            
            // Conditional Button: Sign Up (Guest) vs Sign Out (Member)
            if (Supabase.instance.client.auth.currentSession?.user.isAnonymous ?? true)
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () async {
                    // Capture current guest ID before going to Sign Up / Log In
                    await MigrationManager().prepareForMigration();
                    
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SignupScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary, // Prominent color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Sign Up / Link Account", // Matches PageFlow doc
                        style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Logout Button (Member)
              // Logout Button (Member)
              AnimatedTextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.get('cancel'))),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.get('sign_out'), style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SignOutLandingScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('sign_out'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            const SizedBox(height: 100), // Bottom padding for scrolling
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (isRequired)
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.hostPrimary, // Match primary color (Pink) for required mark
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildGenderChip(String label, String value) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Toggle Logic: If already selected, deselect (null), otherwise select
            if (_selectedGender == value) {
               _selectedGender = null;
            } else {
               _selectedGender = value;
            }
             _checkForChanges();
          });
        },
        child: Container(
          height: 38, // Medium Design System Size
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0C0219) : Colors.white, // Dark if selected
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0C0219) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14, // Body 1
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  
  
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white, // Changed from F5F5F5 to White for clarity
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!), // Added subtle border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!), // Visible border when enabled
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.hostPrimary, width: 1),
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    );
  }
  
  Widget _buildPointsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      // Dark Background #0C0219
      decoration: BoxDecoration(
        color: const Color(0xFF0C0219),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem("VP", _session.vp, isVP: true),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreItem("AP", _session.ap), // No Exchange Button
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreItem("EP", _session.ep), // No Exchange Button
            ],
          ),
          const SizedBox(height: 24),
          // Manage Button (Outlined)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AnimatedOutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PointPurchaseScreen())
                ).then((_) => setState(() {})); 
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 0.5), // Thin Outline
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.get('manage_points'), 
                    style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, {bool isVP = false, VoidCallback? onExchange, String? tooltip}) {
    return Column(
      children: [
        // Score with Animation
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(seconds: 2), // Slower animation (2s)
          builder: (context, value, child) {
             final isAnimating = value != score;
             return Text(
               value.toString(), 
               style: GoogleFonts.alexandria(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold, 
                 color: isAnimating ? Colors.greenAccent : Colors.white // Highlight change
               )
             );
          },
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.hostPrimary,
      ),
    );
  }

  Widget _buildLanguageChip(String label, String value) {
    // Current Language from Session
    final currentLang = _session.language;
    final isSelected = currentLang == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
             _session.setLanguage(value);
          });
        },
        child: Container(
          height: 44, // Slightly taller for settings
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.hostPrimary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.hostPrimary : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: value == 'en' 
                ? GoogleFonts.alexandria(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  )
                : TextStyle(
                    fontFamily: 'EliceDigitalBaeum',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
          ),
        ),
      ),
    );
  }
}
