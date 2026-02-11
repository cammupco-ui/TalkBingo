import 'package:flutter/material.dart';
import 'package:talkbingo_app/models/notice.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkbingo_app/utils/localization.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _supabase = Supabase.instance.client;

  void _showInquiryDialog() {
    final categoryController = TextEditingController(text: AppLocalizations.get('notice_cat_bug')); // Default
    final contentController = TextEditingController();
    final contactController = TextEditingController();
    
    String selectedCategory = AppLocalizations.get('notice_cat_bug');
    final categories = [AppLocalizations.get('notice_cat_bug'), AppLocalizations.get('notice_cat_feature'), AppLocalizations.get('notice_cat_other')];
    bool isSubmitting = false;

    String? errorMessage; // Local state for error

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF333333),
              title: Text(AppLocalizations.get('notice_inquiry_title'), style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: const Color(0xFF444444),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.get('notice_category'),
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      items: categories.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(c, style: const TextStyle(color: Colors.white))
                      )).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.get('notice_content'),
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: AppLocalizations.get('notice_content_hint'),
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.get('notice_contact'),
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: AppLocalizations.get('notice_contact_hint'),
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.get('notice_cancel'), style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.hostPrimary),
                  onPressed: isSubmitting ? null : () async {
                    setState(() => errorMessage = null); // Clear previous error
                    
                    final content = contentController.text.trim();
                    if (content.isEmpty) {
                       setState(() => errorMessage = AppLocalizations.get('notice_content_required'));
                       return;
                    }
                    
                    setState(() => isSubmitting = true);
                    
                    try {
                      final user = _supabase.auth.currentUser;
                      await _supabase.from('inquiries').insert({
                        if (user != null) 'user_id': user.id,
                        'category': selectedCategory,
                        'title': '[$selectedCategory] ${content.length > 30 ? content.substring(0, 30) : content}',
                        'content': content,
                        'contact_info': contactController.text.trim(),
                        'is_private': true,
                        'status': 'submitted',
                      });
                      if (context.mounted) {
                        Navigator.pop(context); // Close Form
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF333333),
                            title: Text(AppLocalizations.get('notice_success_title'), style: const TextStyle(color: Colors.white)),
                            content: Text(AppLocalizations.get('notice_success_msg'), style: const TextStyle(color: Colors.white)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(AppLocalizations.get('notice_ok'), style: const TextStyle(color: AppColors.hostPrimary)),
                              )
                            ],
                          )
                        );
                      }
                    } catch (e) {
                      debugPrint("Inquiry Error: $e");
                      if (context.mounted) {
                         setState(() {
                           isSubmitting = false;
                           // Show friendly message for missing table
                           if (e.toString().contains("relation \"public.inquiries\" does not exist") || e.toString().contains("Could not find the table")) {
                             errorMessage = AppLocalizations.get('notice_server_error');
                           } else {
                             errorMessage = "${AppLocalizations.get('notice_send_fail')}: ${e.toString().split('\n').first}"; // Shorten error
                           }
                         });
                      }
                    }
                  },
                  child: isSubmitting 
                     ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                     : Text(AppLocalizations.get('notice_send')),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/logo_vector.svg',
          height: 30,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Move up above bottom banner
        child: FloatingActionButton.extended(
          onPressed: _showInquiryDialog,
          backgroundColor: AppColors.hostPrimary,
          icon: const Icon(Icons.mail_outline),
          label: Text(AppLocalizations.get('notice_inquiry_btn')),
        ),
      ),
      body: FutureBuilder<List<Notice>>(
        future: NoticeRepository().getNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.hostPrimary));
          }
          if (snapshot.hasError) {
             return Center(child: Text('${AppLocalizations.get('notice_load_error')}\n${snapshot.error}'));
          }
          final notices = snapshot.data ?? [];
          
          if (notices.isEmpty) {
            return Center(child: Text(AppLocalizations.get('notice_empty')));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Icon(
                  notice.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: notice.isRead ? Colors.grey : AppColors.hostPrimary,
                ),
                title: Text(
                  notice.title,
                  style: TextStyle(
                    fontWeight: notice.isRead ? FontWeight.normal : FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(notice.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(notice.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ],
                onExpansionChanged: (expanded) {
                  if (expanded && !notice.isRead) {
                    setState(() {
                      NoticeRepository().markAsRead(notice.id);
                      notice.isRead = true; // Update local model instantly
                    });
                  }
                },
              );
            },
          );
        }
      ),
    );
  }
}
