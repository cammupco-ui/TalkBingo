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
}

class NoticeRepository {
  static final NoticeRepository _instance = NoticeRepository._internal();
  factory NoticeRepository() => _instance;
  NoticeRepository._internal();

  final List<Notice> _notices = [
    Notice(
      id: '1',
      title: 'Welcome to TalkBingo!',
      date: '2024-12-17',
      content: 'Thank you for joining TalkBingo. We are excited to have you on board! Enjoy creating quizzes and playing with friends.',
      isRead: false,
    ),
    Notice(
      id: '2',
      title: 'New Feature: VP Points & Shop',
      date: '2024-12-16',
      content: 'You can now earn VP points by winning games. Use your VP points to remove ads or purchase items in the future shop updates!',
      isRead: false,
    ),
    Notice(
      id: '3',
      title: 'Maintenance Scheduled',
      date: '2024-12-10',
      content: 'Server maintenance is scheduled for Dec 20th from 02:00 AM to 04:00 AM (UTC). Please plan your games accordingly.',
      isRead: true,
    ),
  ];

  List<Notice> getNotices() => _notices;

  int get unreadCount => _notices.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final notice = _notices.firstWhere((n) => n.id == id, orElse: () => _notices.first);
    notice.isRead = true;
  }
}
