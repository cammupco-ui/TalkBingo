import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

class InquiryWriteScreen extends StatefulWidget {
  const InquiryWriteScreen({super.key});

  @override
  State<InquiryWriteScreen> createState() => _InquiryWriteScreenState();
}

class _InquiryWriteScreenState extends State<InquiryWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  String _category = 'General';
  final List<String> _categories = [
    'General', // 일반 문의
    'Bug', // 버그 신고
    'Feature', // 기능 제안
    'Payment', // 결제/포인트
    'Account', // 계정
    'Etc', // 기타
  ];

  bool _isPrivate = true;
  bool _isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // 1. Gather Device Info (Safe for Web/Mobile)
      String appVersion = 'Unknown';
      Map<String, dynamic> deviceInfo = {};
      
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = "${info.version}+${info.buildNumber}";
        
        if (kIsWeb) {
            deviceInfo = {'platform': 'web'};
        } else if (Platform.isAndroid) {
            deviceInfo = {'platform': 'android'}; // Detail via device_info_plus if needed
        } else if (Platform.isIOS) {
            deviceInfo = {'platform': 'ios'};
        }
      } catch (e) {
        debugPrint("Error gathering info: $e");
      }

      // 2. Insert into Supabase
      await _supabase.from('inquiries').insert({
        'user_id': user.id,
        'category': _category,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'is_private': _isPrivate,
        'status': 'submitted',
        'app_version': appVersion,
        'device_info': deviceInfo,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inquiry submitted successfully!')),
        );
        Navigator.pop(context, true); // Return 'true' to trigger refresh
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
          "Write Inquiry",
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
                : Text("Post", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.hostPrimary)),
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
              Text("Category", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
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
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                   labelText: 'Title',
                   hintText: 'Summarize your inquiry',
                   border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),

              // 3. Content Input
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                   labelText: 'Content',
                   hintText: 'Describe your issue or suggestion...',
                   border: OutlineInputBorder(),
                   alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter content' : null,
              ),
              const SizedBox(height: 20),

              // 4. Privacy Toggle
              SwitchListTile(
                 title: const Text("Private Post"),
                 subtitle: const Text("Only you and admins can see this."),
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
                         "Device info and app version will be automatically attached to help us resolve issues faster.",
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
