import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/models/inquiry_model.dart';
import 'package:talkbingo_app/screens/board/inquiry_write_screen.dart';
import 'package:talkbingo_app/screens/board/inquiry_detail_screen.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  List<Inquiry> _myInquiries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text(
          "TalkBingo Board",
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.hostPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.hostPrimary,
          tabs: const [
            Tab(text: "My Inquiries"),
            Tab(text: "Public / Notices"), // Placeholder for now, or just remove if we only want private
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyInquiriesList(),
          _buildPublicList(), // Placeholder
        ],
      ),
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
        label: const Text("Write"),
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
              "No inquiries yet.\nFeel free to ask or suggest anything!",
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myInquiries.length,
      itemBuilder: (context, index) {
        final item = _myInquiries[index];
        return _buildInquiryCard(item);
      },
    );
  }

  Widget _buildPublicList() {
    // For MVP, just show a placeholder or "Feature Coming Soon"
    return Center(
      child: Text(
        "Public board & Notices coming soon!",
        style: GoogleFonts.alexandria(color: Colors.grey),
      ),
    );
  }

  Widget _buildInquiryCard(Inquiry item) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    Color statusColor = Colors.grey;
    if (item.status == 'resolved') statusColor = Colors.green;
    if (item.status == 'in_progress') statusColor = Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InquiryDetailScreen(inquiry: item)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                  const Spacer(),
                  if (item.isPrivate)
                    const Icon(Icons.lock, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(item.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
