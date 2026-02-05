import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'dart:io' removed for Web compatibility
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform
import 'package:talkbingo_app/utils/localization.dart';

class InquiryWriteScreen extends StatefulWidget {
  const InquiryWriteScreen({super.key});

  @override
  State<InquiryWriteScreen> createState() => _InquiryWriteScreenState();
}

class _InquiryWriteScreenState extends State<InquiryWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  // DB Value : Localization Key
  final Map<String, String> _categoryMap = {
    'General': 'cat_general',
    'Bug': 'cat_bug',
    'Feature': 'cat_feature',
    'Payment': 'cat_payment',
    'Account': 'cat_account',
    'Etc': 'cat_etc',
  };
  
  String _category = 'General'; // Default DB Value

  bool _isPrivate = true;
  bool _isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // 1. Gather Device Info
      String appVersion = 'Unknown';
      Map<String, dynamic> deviceInfo = {};
      
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = "${info.version}+${info.buildNumber}";
        
        if (kIsWeb) {
            deviceInfo = {'platform': 'web'};
        } else if (defaultTargetPlatform == TargetPlatform.android) {
            deviceInfo = {'platform': 'android'}; 
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            deviceInfo = {'platform': 'ios'};
        }
      } catch (e) {
        debugPrint("Error gathering info: $e");
      }

      // 2. Insert into Supabase
      await _supabase.from('inquiries').insert({
        'user_id': user.id,
        'category': _category, // Store Internal English Key in DB
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'is_private': _isPrivate,
        'status': 'submitted',
        'app_version': appVersion,
        'device_info': deviceInfo,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.get('inquiry_submitted'))), // Localized
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.get('write_title'), // Localized
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitInquiry,
            child: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(AppLocalizations.get('post_btn'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.hostPrimary)), // Localized
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Category Dropdown
              Text(AppLocalizations.get('category_label'), style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)), // Localized
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: Colors.white, // Force white background for menu
                    style: GoogleFonts.alexandria(color: Colors.black, fontSize: 16), // Force black text
                    items: _categoryMap.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(AppLocalizations.get(entry.value)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Title Input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                   labelText: AppLocalizations.get('title_label'), // Localized
                   hintText: AppLocalizations.get('title_hint'), // Localized
                   border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),

              // 3. Content Input
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                   labelText: AppLocalizations.get('content_label'), // Localized
                   hintText: AppLocalizations.get('content_hint'), // Localized
                   border: const OutlineInputBorder(),
                   alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter content' : null,
              ),
              const SizedBox(height: 20),

              // 4. Privacy Toggle
              SwitchListTile(
                 title: Text(AppLocalizations.get('private_post')), // Localized
                 subtitle: Text(AppLocalizations.get('private_post_desc')), // Localized
                 value: _isPrivate,
                 activeColor: AppColors.hostPrimary,
                 onChanged: (val) => setState(() => _isPrivate = val),
                 contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                   children: [
                     const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         AppLocalizations.get('device_info_notice'), // Localized
                         style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey[600]),
                       ),
                     ),
                   ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
