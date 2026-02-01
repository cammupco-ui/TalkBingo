import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Notice {
  final String id;
  final String title;
  final String date;
  final String content;
  bool isRead;

  Notice({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    this.isRead = false,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: (json['created_at'] as String).substring(0, 10), // YYYY-MM-DD
      isRead: false, // Default unread, handled locally
    );
  }
}

class NoticeRepository {
  static final NoticeRepository _instance = NoticeRepository._internal();
  factory NoticeRepository() => _instance;
  NoticeRepository._internal();

  final _supabase = Supabase.instance.client;
  
  // Local cache for read status could be stored in SharedPreferences in a real app
  // For now, we will just track read status in memory for the session
  final Set<String> _readNoticeIds = {};
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<List<Notice>> getNotices() async {
    try {
      final response = await _supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      final notices = data.map((json) {
        final notice = Notice.fromJson(json);
        // Restore read status
        if (_readNoticeIds.contains(notice.id)) {
          notice.isRead = true;
        }
        return notice;
      }).toList();

      // Update unread count
      _unreadCount = notices.where((n) => !n.isRead).length;
      
      return notices;
    } catch (e) {
      debugPrint('Error fetching notices: $e');
      return []; // Return empty on error
    }
  }

  void markAsRead(String id) {
    if (!_readNoticeIds.contains(id)) {
      _readNoticeIds.add(id);
      if (_unreadCount > 0) {
        _unreadCount--;
      }
    }
  }
}
