import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added Import
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/styles/app_spacing.dart';
import 'package:talkbingo_app/utils/localization.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _snsController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedAge;
  String? _selectedGender;
  String? _selectedProvince;
  String? _selectedCity;

  bool _regionConsent = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  String? _userEmail; // Added for email display

  final GameSession _session = GameSession();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserEmail(); // Fetch Email

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
  
  void _loadUserEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _userEmail = user?.email;
    });
  }

  void _loadUserData() {
    _nicknameController.text = _session.hostNickname ?? '';
    _birthDateController.text = _session.hostBirthDate ?? '';
    _phoneController.text = _session.hostPhone ?? '';
    _snsController.text = _session.hostSns ?? '';
    _addressController.text = _session.hostAddress ?? '';
    _regionConsent = _session.hostRegionConsent ?? false;

    _selectedAge = _session.hostAge;
    _selectedGender = _session.hostGender;
    _selectedProvince = _session.hostHometownProvince;
    _selectedCity = _session.hostHometownCity;
  }

  void _checkForChanges() {
    bool hasChanged =
        _nicknameController.text != (_session.hostNickname ?? '') ||
        _birthDateController.text != (_session.hostBirthDate ?? '') ||
        _phoneController.text != (_session.hostPhone ?? '') ||
        _snsController.text != (_session.hostSns ?? '') ||
        _addressController.text != (_session.hostAddress ?? '') ||
        _regionConsent != (_session.hostRegionConsent ?? false) ||
        _selectedGender != _session.hostGender;
    
    setState(() {
      _hasChanges = hasChanged;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    _session.hostNickname = _nicknameController.text;
    _session.hostBirthDate = _birthDateController.text;
    _session.hostPhone = _phoneController.text;
    _session.hostSns = _snsController.text;
    _session.hostAddress = _addressController.text;
    _session.hostRegionConsent = _regionConsent;
    _session.hostGender = _selectedGender;

    await _session.saveProfile();

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('settings_saved')), backgroundColor: AppColors.hostPrimary),
      );
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: SvgPicture.asset('assets/images/Logo Vector.svg', height: 32),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _hasChanges ? _saveProfile : null,
              child: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    AppLocalizations.get('save_changes'), 
                    style: TextStyle(
                      color: _hasChanges ? AppColors.hostPrimary : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NURA', // NURA font for Save button
                    )
                  ),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Account Section
              _buildSectionHeader(AppLocalizations.get('account') ?? 'Account', const Color(0xFF6B14EC)), // Purple
              const SizedBox(height: 12),
              _buildCard(
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                         _userEmail ?? 'Guest User',
                         style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 32),


              // 2. Required Info Section
              _buildSectionHeader(AppLocalizations.get('required_info') ?? 'Required Info', const Color(0xFFBD0558)), // Pink
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                     // Nickname
                    _buildLabel(AppLocalizations.get('nickname'), isRequired: true),
                    TextField(
                      controller: _nicknameController,
                      decoration: _inputDecoration('Nickname'),
                      style: const TextStyle(fontSize: AppSpacing.inputFontSize),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    _buildLabel(AppLocalizations.get('gender'), isRequired: true),
                    Row(
                      children: [
                        _buildGenderChip(AppLocalizations.get('male'), 'Male'),
                        const SizedBox(width: 10),
                        _buildGenderChip(AppLocalizations.get('female'), 'Female'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Birth Date
                    _buildLabel(AppLocalizations.get('birth_date'), isRequired: true),
                    TextField(
                      controller: _birthDateController,
                      decoration: _inputDecoration('YYYY-MM-DD'),
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(fontSize: AppSpacing.inputFontSize),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 32),


              // 3. Optional Info Section
              _buildSectionHeader(AppLocalizations.get('optional_info') ?? 'Optional Info', const Color(0xFF68CDFF)), // Blue
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    // SNS
                    _buildLabel(AppLocalizations.get('sns')),
                    TextField(
                      controller: _snsController,
                      decoration: _inputDecoration('@username'),
                      style: const TextStyle(fontSize: AppSpacing.inputFontSize),
                    ),
                    const SizedBox(height: 16),

                     // Address
                    _buildLabel(AppLocalizations.get('address')),
                    TextField(
                      controller: _addressController,
                      decoration: _inputDecoration('City, District'),
                      style: const TextStyle(fontSize: AppSpacing.inputFontSize),
                    ),
                    const SizedBox(height: 16),
                    
                     // Phone
                    _buildLabel(AppLocalizations.get('phone_number')),
                    TextField(
                      controller: _phoneController,
                      decoration: _inputDecoration('010-1234-5678'),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: AppSpacing.inputFontSize),
                    ),
                    const SizedBox(height: 24),

                    // Region Consent
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inputPaddingHorizontal, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
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
                                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
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
                      value: true, 
                      onChanged: (val) {},
                    ),
                  ],
                )
              ),
              
              const SizedBox(height: 32),
              
              // Bottom Save Button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: AnimatedButton(
                  onPressed: _hasChanges ? _saveProfile : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges ? AppColors.hostPrimary : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
                  ),
                  child: _isSaving 
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : Text(AppLocalizations.get('save_changes'), style: AppLocalizations.getTextStyle(baseStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSpacing.buttonFontSize))),
                ),
              ),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(String title, Color barColor) {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 18, 
          decoration: BoxDecoration(
            color: barColor, 
            borderRadius: BorderRadius.circular(2)
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Dark text for header
            fontFamily: 'NURA', // Optional: Use NURA if desired for headers, or system font
          ),
        ),
        const Spacer(),
        Container(height: 1, width: 200, color: Colors.grey[200]), // Divider line effect? Or just spacer
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingXs),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13, // Slightly smaller label
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
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
                  color: AppColors.hostPrimary,
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
            if (_selectedGender == value) {
               _selectedGender = null;
            } else {
               _selectedGender = value;
            }
             _checkForChanges();
          });
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0C0219) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            border: Border.all(
              color: isSelected ? const Color(0xFF0C0219) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA), // Very light gray for input background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        borderSide: const BorderSide(color: AppColors.hostPrimary, width: 1.5),
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      contentPadding: AppSpacing.inputContentPadding,
      isDense: true,
    );
  }
}
