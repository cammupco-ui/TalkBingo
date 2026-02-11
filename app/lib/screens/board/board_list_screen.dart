import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/inquiry_model.dart';
import 'package:talkbingo_app/screens/board/inquiry_write_screen.dart';
import 'package:talkbingo_app/screens/board/inquiry_detail_screen.dart';
import 'package:talkbingo_app/utils/localization.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Inquiry> _myInquiries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch My Inquiries
      final response = await _supabase
          .from('inquiries')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      _myInquiries = data.map((json) => Inquiry.fromJson(json)).toList();

    } catch (e) {
      debugPrint('Error fetching inquiries: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load board: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/logo_vector.svg',
          height: 30,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildMyInquiriesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InquiryWriteScreen()),
          );
          if (result == true) {
            _fetchInquiries(); // Refresh if posted
          }
        },
        backgroundColor: AppColors.hostPrimary,
        icon: const Icon(Icons.edit),
        label: Text(AppLocalizations.get('write_btn')),
      ),
    );
  }

  Widget _buildMyInquiriesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_myInquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('no_inquiries'),
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInquiries,
      color: AppColors.hostPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myInquiries.length,
        itemBuilder: (context, index) {
          final item = _myInquiries[index];
          return _buildInquiryCard(item);
        },
      ),
    );
  }

  Widget _buildInquiryCard(Inquiry item) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    Color statusColor = Colors.grey;
    String statusText = item.status.toUpperCase();
    
    // Localize Status
    if (item.status == 'submitted') {
       statusText = AppLocalizations.get('status_submitted');
    } else if (item.status == 'in_progress') {
       statusText = AppLocalizations.get('status_progress');
       statusColor = Colors.orange;
    } else if (item.status == 'resolved') {
       statusText = AppLocalizations.get('status_resolved');
       statusColor = Colors.green;
    }
    
    // Localize Category Display
    String displayCategory = item.category;
    if (item.category == 'General') displayCategory = AppLocalizations.get('cat_general');
    if (item.category == 'Bug') displayCategory = AppLocalizations.get('cat_bug');
    if (item.category == 'Feature') displayCategory = AppLocalizations.get('cat_feature');
    if (item.category == 'Payment') displayCategory = AppLocalizations.get('cat_payment');
    if (item.category == 'Account') displayCategory = AppLocalizations.get('cat_account');
    if (item.category == 'Etc') displayCategory = AppLocalizations.get('cat_etc');

    // Admin check status
    final bool isChecked = item.adminChecked || item.status == 'resolved';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InquiryDetailScreen(inquiry: item)),
          );
          _fetchInquiries(); // Refresh on return
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: category + date + admin check
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
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                  const Spacer(),
                  // Admin check indicator
                  if (isChecked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 2),
                          Text('Checked', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  if (isChecked) const SizedBox(width: 8),
                  Text(
                    dateFormat.format(item.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Bottom row: status + reply count
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  // Reply count badge
                  if (item.replyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.hostPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply, size: 12, color: AppColors.hostPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '${item.replyCount}',
                            style: const TextStyle(fontSize: 10, color: AppColors.hostPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
