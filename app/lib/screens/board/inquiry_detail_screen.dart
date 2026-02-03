import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/inquiry_model.dart';
import 'package:talkbingo_app/utils/localization.dart';

class InquiryDetailScreen extends StatefulWidget {
  final Inquiry inquiry;

  const InquiryDetailScreen({super.key, required this.inquiry});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _replies = [];
  bool _isLoadingReplies = true;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  Future<void> _fetchReplies() async {
    try {
      final response = await _supabase
          .from('inquiry_replies')
          .select()
          .eq('inquiry_id', widget.inquiry.id)
          .order('created_at', ascending: true);
      
      if (mounted) {
        setState(() {
          _replies = List<Map<String, dynamic>>.from(response);
          _isLoadingReplies = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching replies: $e");
      if (mounted) setState(() => _isLoadingReplies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    
    // Localize Category
    String displayCategory = widget.inquiry.category;
    if (widget.inquiry.category == 'General') displayCategory = AppLocalizations.get('cat_general');
    if (widget.inquiry.category == 'Bug') displayCategory = AppLocalizations.get('cat_bug');
    if (widget.inquiry.category == 'Feature') displayCategory = AppLocalizations.get('cat_feature');
    if (widget.inquiry.category == 'Payment') displayCategory = AppLocalizations.get('cat_payment');
    if (widget.inquiry.category == 'Account') displayCategory = AppLocalizations.get('cat_account');
    if (widget.inquiry.category == 'Etc') displayCategory = AppLocalizations.get('cat_etc');


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.get('inquiry_details'), // Localized
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayCategory,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(widget.inquiry.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const Spacer(),
                _buildStatusBadge(widget.inquiry.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            SelectableText(
              widget.inquiry.title,
              style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50], // Very light grey for content
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SelectableText(
                widget.inquiry.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            
            // Replies Section
            const Divider(),
            const SizedBox(height: 16),
            Text(AppLocalizations.get('admin_response'), style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 16)), // Localized
            const SizedBox(height: 16),
            
            if (_isLoadingReplies)
               const Center(child: CircularProgressIndicator())
            else if (_replies.isEmpty)
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.grey[100],
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Column(
                   children: [
                     Icon(Icons.hourglass_empty, color: Colors.grey[400]),
                     const SizedBox(height: 8),
                     Text(
                       AppLocalizations.get('waiting_response'), // Localized
                       style: TextStyle(color: Colors.grey[500]),
                     ),
                   ],
                 ),
               )
            else
               ..._replies.map((reply) => _buildReplyCard(reply)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status.toUpperCase();

    // Localize Status
    if (status == 'submitted') {
       text = AppLocalizations.get('status_submitted');
    } else if (status == 'in_progress') {
       text = AppLocalizations.get('status_progress');
       color = Colors.orange;
    } else if (status == 'resolved') {
       text = AppLocalizations.get('status_resolved');
       color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply) {
    final date = DateTime.parse(reply['created_at']);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hostPrimary.withOpacity(0.05), // Light primary tint
        border: Border.all(color: AppColors.hostPrimary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, size: 16, color: AppColors.hostPrimary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.get('talkbingo_team'), // Localized
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.hostPrimary),
              ),
              const Spacer(),
              Text(
                dateFormat.format(date),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            reply['content'] ?? '',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
